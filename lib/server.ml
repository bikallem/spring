type request = Request.server Request.t

type response = Response.server Response.t

type handler = request -> response

let not_found_handler : handler = fun (_ : request) -> Response.not_found

type pipeline = handler -> handler

(* RFC 9112 states that host is required in server requests and server MUST
    send bad request if Host header value is not correct.

    https://www.rfc-editor.org/rfc/rfc9112#section-3.2

    TODO bikal add tests for IPv6 host parsing after
    https://github.com/mirage/ocaml-uri/pull/169 if merged. *)
let host_header : pipeline =
 fun (next : handler) req ->
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
  let headers = Response.headers res in
  match Header.(find_opt headers date) with
  | Some _ -> res
  | None -> (
    match Response.status res with
    | status when Status.informational status || Status.server_error status ->
      res
    | _ ->
      let now = Eio.Time.now clock |> Ptime.of_float_s |> Option.get in
      let headers = Header.(add_unless_exists headers date now) in
      let version = Response.version res in
      let status = Response.status res in
      let body = Response.body res in
      Response.make_server_response ~version ~headers ~status body)

let strict_http clock next = response_date clock @@ host_header @@ next

type router = response Router.t

let router_pipeline : router -> pipeline =
 fun router next req ->
  match Router.match' req router with
  | Some response -> response
  | None -> next req

let session_pipeline (session_codec : Session.codec) : pipeline =
 fun next req ->
  let cookie_name = Session.cookie_name session_codec in
  (match Request.find_cookie cookie_name req with
  | Some data ->
    let session_data = Session.decode data session_codec in
    Request.replace_session_data session_data req
  | None -> ());
  let response = next req in
  match Request.session_data req with
  | None -> response
  | Some session_data ->
    let nonce = Mirage_crypto_rng.generate Secret.nonce_size in
    let encrypted_data = Session.encode ~nonce session_data session_codec in
    let cookie =
      Set_cookie.make ~path:"/" ~same_site:Set_cookie.strict
        (cookie_name, encrypted_data)
    in
    Response.add_set_cookie cookie response

type 'a t =
  { clock : Eio.Time.clock
  ; net : Eio.Net.t
  ; handler : handler
  ; run : Eio.Net.listening_socket -> Eio.Net.connection_handler -> unit
  ; stop_u : unit Eio.Promise.u
  }

type http = handler

let make_http_server
    ?(max_connections = Int.max_int)
    ?additional_domains
    ~on_error
    (clock : #Eio.Time.clock)
    (net : #Eio.Net.t)
    handler =
  let stop, stop_u = Eio.Promise.create () in
  let run =
    Eio.Net.run_server ~max_connections ?additional_domains ~stop ~on_error
  in
  { clock = (clock :> Eio.Time.clock)
  ; net = (net :> Eio.Net.t)
  ; handler
  ; run
  ; stop_u
  }

type app = response Router.t

let empty_router = Router.empty

let make_app_server
    ?(max_connections = Int.max_int)
    ?additional_domains
    ?(handler = not_found_handler)
    ?session_codec
    ?master_key
    ~on_error
    ~secure_random
    (clock : #Eio.Time.clock)
    (net : #Eio.Net.t)
    router =
  let stop, stop_u = Eio.Promise.create () in
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
  { clock = (clock :> Eio.Time.clock)
  ; net = (net :> Eio.Net.t)
  ; handler =
      strict_http clock
      @@ session_pipeline session_codec
      @@ router_pipeline router
      @@ handler
  ; run =
      (fun socket handler ->
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
              ~on_error socket handler))
  ; stop_u
  }

type 'a request_target = ('a, response) Router.request_target

let add_route = Router.add

let get rt f app = Router.add Method.get rt f app

let head rt f t = Router.add Method.head rt f t

let delete rt f t = Router.add Method.delete rt f t

let post rt f t = Router.add Method.post rt f t

let put rt f t = Router.add Method.put rt f t

let rec handle_request clock client_addr reader writer flow handler =
  let write = Response.write_server_response writer in
  match Request.parse_server_request client_addr reader with
  | req ->
    let response = handler req in
    write response;
    if Request.keep_alive req then
      handle_request clock client_addr reader writer flow handler
  | (exception End_of_file)
  | (exception Eio.Io (Eio.Net.E (Connection_reset _), _)) -> ()
  | exception (Failure _ as ex) ->
    write Response.bad_request;
    raise ex
  | exception ex ->
    write Response.internal_server_error;
    raise ex

let connection_handler handler clock flow client_addr =
  let reader = Buf_read.of_flow ~initial_size:0x1000 ~max_size:max_int flow in
  Eio.Buf_write.with_flow flow (fun writer ->
      handle_request clock client_addr reader writer flow handler)

let run socket t =
  let connection_handler = connection_handler t.handler t.clock in
  t.run socket connection_handler

let run_local ?(reuse_addr = true) ?(socket_backlog = 128) ?(port = 80) t =
  Eio.Switch.run @@ fun sw ->
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  let socket =
    Eio.Net.listen ~reuse_addr ~backlog:socket_backlog ~sw t.net addr
  in
  run socket t

let shutdown t = Eio.Promise.resolve t.stop_u ()
