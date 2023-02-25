type handler = Request.server_request -> Response.server_response

type pipeline = handler -> handler

type t =
  { clock : Eio.Time.clock
  ; net : Eio.Net.t
  ; handler : handler
  ; run : Eio.Net.listening_socket -> Eio.Net.connection_handler -> unit
  ; stop_r : unit Eio.Promise.u
  }

let make ?(max_connections = Int.max_int) ?additional_domains ~on_error
    (clock : #Eio.Time.clock) (net : #Eio.Net.t) handler =
  let stop, stop_r = Eio.Promise.create () in
  let run =
    Eio.Net.run_server ~max_connections ?additional_domains ~stop ~on_error
  in
  { clock = (clock :> Eio.Time.clock)
  ; net = (net :> Eio.Net.t)
  ; handler
  ; run
  ; stop_r
  }

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
  match Header.(find headers date) with
  | Some _ -> res
  | None -> (
    match res#status with
    | status when Status.informational status || Status.server_error status ->
      res
    | _ ->
      let date_v = Date.http_date clock in
      let headers = Header.(add_unless_exists headers date date_v) in
      Response.server_response ~version:res#version ~headers ~status:res#status
        res)

let strict_http clock next = response_date clock @@ host_header @@ next

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
  Buf_write.with_flow flow (fun writer ->
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

let shutdown t = Eio.Promise.resolve t.stop_r ()

let not_found_handler _ = Response.not_found
