type handler = Request.Server.t -> Response.Server.t

let not_found_handler : handler =
 fun (_ : Request.Server.t) -> Response.Server.not_found

type pipeline = handler -> handler

(* RFC 9112 states that host is required in server requests and server MUST
    send bad request if Host header value is not correct.

    https://www.rfc-editor.org/rfc/rfc9112#section-3.2

    TODO bikal add tests for IPv6 host parsing after
    https://github.com/mirage/ocaml-uri/pull/169 if merged. *)
let host_header : pipeline =
 fun (next : handler) (req : Request.Server.t) ->
  let hosts = Header.(find_all req.headers host) in
  let len = List.length hosts in
  if len = 0 || len > 1 then Response.Server.bad_request
  else
    let host = List.hd hosts in
    match Uri.of_string ("//" ^ host) |> Uri.host with
    | Some _ -> next req
    | None -> Response.Server.bad_request

(* A request pipeline that adds "Date" header if required.

   https://www.rfc-editor.org/rfc/rfc9110#section-6.6.1 *)
let response_date : #Eio.Time.clock -> pipeline =
 fun clock next req ->
  let res = next req in
  let headers = res.headers in
  match Header.(find_opt headers date) with
  | Some _ -> res
  | None -> (
    match res.status with
    | status when Status.informational status || Status.server_error status ->
      res
    | _ ->
      let now = Eio.Time.now clock |> Ptime.of_float_s |> Option.get in
      let headers = Header.(add_unless_exists headers date now) in
      Response.Server.make ~version:res.version ~headers ~status:res.status
        res.body)

let strict_http clock next = response_date clock @@ host_header @@ next

let router_pipeline : Response.Server.t Router.t -> pipeline =
 fun router next req ->
  match Router.match' req router with
  | Some response -> response
  | None -> next req

let session_pipeline (session : #Session.codec) : pipeline =
 fun next req ->
  let cookie_name = session#cookie_name in
  (match Request.Server.find_cookie cookie_name req with
  | Some data ->
    let session_data = Session.decode data session in
    Request.Server.replace_session_data session_data req
  | None -> ());
  let response = next req in
  match req.session_data with
  | None -> response
  | Some session_data ->
    let nonce = Mirage_crypto_rng.generate Secret.nonce_size in
    let encrypted_data = Session.encode ~nonce session_data session in
    let cookie =
      Set_cookie.make ~path:"/" ~same_site:Set_cookie.strict
        (cookie_name, encrypted_data)
    in
    Response.Server.add_set_cookie cookie response

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

type 'a request_target = ('a, Response.Server.t) Router.request_target

class virtual app_server =
  object (_ : 'a)
    inherit t
    method virtual session_codec : Session.codec
    method virtual router : Response.Server.t Router.t
    method virtual add_route : 'f. Method.t -> 'f request_target -> 'f -> 'a
  end

let app_server
    ?(max_connections = Int.max_int)
    ?additional_domains
    ?(handler = not_found_handler)
    ?session_codec
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
  let session_codec =
    match session_codec with
    | Some x -> (x :> Session.codec)
    | None -> (Session.cookie_codec key :> Session.codec)
  in
  object (self)
    val router = Router.empty
    method clock = (clock :> Eio.Time.clock)
    method net = (net :> Eio.Net.t)
    method session_codec = session_codec

    method handler =
      let r = self#router in
      strict_http clock
      @@ session_pipeline session_codec
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
  match Request.Server.parse client_addr reader with
  | req ->
    let response = handler req in
    Response.Server.write writer response;
    if Request.Server.keep_alive req then
      handle_request clock client_addr reader writer flow handler
  | (exception End_of_file)
  | (exception Eio.Io (Eio.Net.E (Connection_reset _), _)) -> ()
  | exception (Failure _ as ex) ->
    Response.Server.(write writer bad_request);
    raise ex
  | exception ex ->
    Response.Server.(write writer internal_server_error);
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
