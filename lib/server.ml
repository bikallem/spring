type handler = Request.server_request -> Response.server_response

let not_found_handler _ = Response.not_found

type pipeline = handler -> handler

(* RFC 9112 states that host is required in server requests and server MUST
    send bad request if Host header value is not correct.

    https://www.rfc-editor.org/rfc/rfc9112#section-3.2

    TODO bikal add tests for IPv6 host parsing after
    https://github.com/mirage/ocaml-uri/pull/169 if merged. *)
let host_header : pipeline =
 fun (next : handler) (req : Request.server_request) ->
  let headers = Request.headers req in
  let hosts = Header.(find_all headers host) in
  let len = List.length hosts in
  if len = 0 || len > 1 then Response.bad_request
  else
    let host = List.hd hosts in
    match Uri.of_string ("//" ^ host) |> Uri.host with
    | Some _ -> next req
    | None -> Response.bad_request

(* A request pipeline that adds "Date" header if required.

   https://www.rfc-editor.org/rfc/rfc9110#section-6.6.1 *)
let response_date : #Eio.Time.clock -> pipeline =
 fun clock next req ->
  let res = next req in
  let headers = Response.headers res |> Header.clean_dup in
  match Header.(find_opt headers date) with
  | Some _ -> res
  | None -> (
    match res#status with
    | status when Status.informational status || Status.server_error status ->
      res
    | _ ->
      let now = Eio.Time.now clock |> Ptime.of_float_s |> Option.get in
      let headers = Header.(add_unless_exists headers date now) in
      Response.server_response ~version:res#version ~headers ~status:res#status
        res)

let strict_http clock next = response_date clock @@ host_header @@ next

let router_pipeline : Response.server_response Router.t -> pipeline =
 fun router next req ->
  match Router.match' req router with
  | Some response -> response
  | None -> next req

let cookie_session ~cookie_name ~key next req =
  match Request.find_cookie cookie_name req with
  | Some data ->
    let session = Session.cookie_session ~data key in
    let req = req#update_session session in
    let response = next req in
    let nonce = Mirage_crypto_rng.generate Secret.nonce_size in
    let session = Option.get req#session in
    let encrypted_data = Session.encode ~nonce session in
    let cookie =
      Set_cookie.make ~path:"/" ~same_site:Set_cookie.strict
        (cookie_name, encrypted_data)
    in
    Response.add_set_cookie cookie response
  | None -> next req

class virtual t =
  object
    method virtual clock : Eio.Time.clock
    method virtual net : Eio.Net.t
    method virtual handler : handler

    method virtual run
        : Eio.Net.listening_socket -> Eio.Net.connection_handler -> unit

    method virtual stop : unit
  end

let make
    ?(max_connections = Int.max_int)
    ?additional_domains
    ~on_error
    (clock : #Eio.Time.clock)
    (net : #Eio.Net.t)
    handler =
  let stop, stop_r = Eio.Promise.create () in
  let run =
    Eio.Net.run_server ~max_connections ?additional_domains ~stop ~on_error
  in
  object
    method clock = (clock :> Eio.Time.clock)
    method net = (net :> Eio.Net.t)
    method handler = handler
    method run = run
    method stop = Eio.Promise.resolve stop_r ()
  end

type 'a request_target = ('a, Response.server_response) Router.request_target

class virtual app_server ~session_cookie_name =
  object (_ : 'a)
    inherit t
    method session_cookie_name : string = session_cookie_name
    method virtual router : Response.server_response Router.t
    method virtual add_route : 'f. Method.t -> 'f request_target -> 'f -> 'a
  end

let app_server
    ?(max_connections = Int.max_int)
    ?additional_domains
    ?(handler = not_found_handler)
    ?(session_cookie_name = "___SPRING_SESSION___")
    ?master_key
    ~on_error
    ~secure_random
    (clock : #Eio.Time.clock)
    (net : #Eio.Net.t) =
  let stop, stop_r = Eio.Promise.create () in
  let key =
    match master_key with
    | Some key -> key
    | None ->
      let key =
        match Sys.getenv_opt "SPRING_MASTER_KEY" with
        | Some key -> key
        | None ->
          In_channel.(with_open_text "master.key" (fun ic -> input_all ic))
      in
      Base64.decode_exn ~pad:false key
  in
  object (self)
    val router = Router.empty
    method session_cookie_name = session_cookie_name
    method clock = (clock :> Eio.Time.clock)
    method net = (net :> Eio.Net.t)

    method handler =
      let r = self#router in
      strict_http clock
      @@ cookie_session ~cookie_name:session_cookie_name ~key
      @@ router_pipeline r
      @@ handler

    method run socket handler =
      let env =
        (object
           method clock = clock
           method secure_random = (secure_random :> Eio.Flow.source)
         end
          :> Mirage_crypto_rng_eio.env)
      in
      Mirage_crypto_rng_eio.run
        (module Mirage_crypto_rng.Fortuna)
        env
        (fun () ->
          Eio.Net.run_server ~max_connections ?additional_domains ~stop
            ~on_error socket handler)

    method stop = Eio.Promise.resolve stop_r ()
    method router = router

    method add_route : type f. Method.t -> f request_target -> f -> #app_server
        =
      fun meth rt f -> {<router = Router.add meth rt f router>}
  end

let add_route meth request_target f (t : #app_server) =
  let t = (t :> app_server) in
  t#add_route meth request_target f

let get rt f (t : #app_server) = add_route Method.get rt f t
let head rt f (t : #app_server) = add_route Method.head rt f t
let delete rt f (t : #app_server) = add_route Method.delete rt f t
let post rt f (t : #app_server) = add_route Method.post rt f t
let put rt f (t : #app_server) = add_route Method.put rt f t

let rec handle_request clock client_addr reader writer flow handler =
  match Request.parse client_addr reader with
  | request ->
    let response = handler request in
    Response.write response writer;
    if Request.keep_alive request then
      handle_request clock client_addr reader writer flow handler
  | (exception End_of_file)
  | (exception Eio.Io (Eio.Net.E (Connection_reset _), _)) -> ()
  | exception (Failure _ as ex) ->
    Response.(write bad_request writer);
    raise ex
  | exception ex ->
    Response.(write internal_server_error writer);
    raise ex

let connection_handler handler clock flow client_addr =
  let reader = Buf_read.of_flow ~initial_size:0x1000 ~max_size:max_int flow in
  Eio.Buf_write.with_flow flow (fun writer ->
      handle_request clock client_addr reader writer flow handler)

let run socket (t : #t) =
  let connection_handler = connection_handler t#handler t#clock in
  t#run socket connection_handler

let run_local ?(reuse_addr = true) ?(socket_backlog = 128) ?(port = 80) (t : #t)
    =
  Eio.Switch.run @@ fun sw ->
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  let socket =
    Eio.Net.listen ~reuse_addr ~backlog:socket_backlog ~sw t#net addr
  in
  run socket t

let shutdown (t : #t) = t#stop
