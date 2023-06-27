type request = Request.server Request.t

type response = Response.server Response.t

(* handler *)
type handler = request -> response

let not_found_handler : handler = fun (_ : request) -> Response.not_found

(* pipeline *)

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

let router_pipeline : response Router.t -> pipeline =
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

type t =
  { clock : Eio.Time.clock
  ; net : Eio.Net.t
  ; master_key : string (* encryption/decyption key - Base64 encoded. *)
  ; session_codec : Session.codec option
  ; make_handler : make_handler
  ; run : Eio.Net.listening_socket -> Eio.Net.connection_handler -> unit
  ; stop_u : unit Eio.Promise.u
  ; router : response Router.t
  }

and make_handler = t -> handler

let default_make_handler t =
  let session_codec =
    match t.session_codec with
    | Some x -> x
    | None -> Session.cookie_codec t.master_key
  in
  response_date t.clock
  @@ host_header
  @@ session_pipeline session_codec
  @@ router_pipeline t.router
  @@ not_found_handler

let clock t = t.clock

let net t = t.net

let master_key t = t.master_key

let session_codec t = t.session_codec

let make_handler t = t.make_handler

let router t = t.router

let make
    ?(max_connections = Int.max_int)
    ?additional_domains
    ?make_handler
    ?session_codec
    ?master_key
    ~on_error
    ~secure_random
    clock
    net =
  let stop, stop_u = Eio.Promise.create () in
  let master_key =
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
  let clock = (clock :> Eio.Time.clock) in
  let net = (net :> Eio.Net.t) in
  let make_handler =
    match make_handler with
    | Some mh -> mh
    | None -> default_make_handler
  in
  let run socket handler =
    Eio.Fiber.first
      (fun () -> Eio.Promise.await stop)
      (fun () ->
        let env =
          (object
             method clock = clock

             method secure_random = (secure_random :> Eio.Flow.source)
           end
            :> Mirage_crypto_rng_eio.env)
        in
        Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env
        @@ fun () ->
        Eio.Net.run_server ~max_connections ?additional_domains ~stop ~on_error
          socket handler)
  in
  { clock
  ; net
  ; master_key
  ; session_codec
  ; make_handler
  ; run
  ; stop_u
  ; router = Router.empty
  }

type 'a request_target = ('a, response) Router.request_target

let add_route : Method.t -> 'f request_target -> 'f -> t -> t =
 fun meth rt f t ->
  let router = Router.add meth rt f t.router in
  { t with router }

let get rt f t = add_route Method.get rt f t

let head rt f t = add_route Method.head rt f t

let delete rt f t = add_route Method.delete rt f t

let post rt f t = add_route Method.post rt f t

let put rt f t = add_route Method.put rt f t

(*-- File Server --*)

let file_last_modified filepath =
  Eio.Path.with_open_in filepath @@ fun p ->
  (Eio.File.stat p).mtime |> Ptime.of_float_s |> Option.get

let serve_file_ ~on_error filepath =
  match
    let content = Eio.Path.load filepath in
    let ct =
      Fpath.v @@ snd filepath
      |> Fpath.filename
      |> Magic_mime.lookup
      |> String.cut ~sep:"/"
      |> Option.get
      |> Content_type.make
    in
    let headers =
      Eio.Path.with_open_in filepath @@ fun p ->
      (Eio.File.stat p).mtime
      |> Ptime.of_float_s
      |> Option.get
      |> Header.(add empty last_modified)
    in
    let body = Body.writable_content ct content in
    Response.make_server_response ~headers body
  with
  | res -> res
  | exception Eio.Io (Eio.Fs.E (Not_found _), _) -> Response.not_found
  | exception exn -> on_error exn

let file_not_modified_response req last_modified' =
  let headers = Header.(add empty last_modified last_modified') in
  let version = Request.version req in
  let status = Status.not_modified in
  Response.make_server_response ~version ~status ~headers Body.none

let serve_dir ~on_error ~dir_path url t =
  let get_handler filepath (req : Request.server Request.t) =
    let filepath = Eio.Path.(dir_path / filepath) in
    match Header.(find_opt (Request.headers req) if_modified_since) with
    | Some if_modified_since ->
      let last_modified' = file_last_modified filepath in
      if Ptime.is_later last_modified' ~than:if_modified_since then
        serve_file_ ~on_error filepath
      else file_not_modified_response req last_modified'
    | None -> serve_file_ ~on_error filepath
  in
  get url get_handler t

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
  let connection_handler = connection_handler (t.make_handler t) t.clock in
  t.run socket connection_handler

let run_local ?(reuse_addr = true) ?(socket_backlog = 128) ?(port = 80) t =
  Eio.Switch.run @@ fun sw ->
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  let socket =
    Eio.Net.listen ~reuse_addr ~backlog:socket_backlog ~sw t.net addr
  in
  run socket t

let shutdown t = Eio.Promise.resolve t.stop_u ()
