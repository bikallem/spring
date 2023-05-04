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

class virtual t =
  object
    method virtual clock : Eio.Time.clock
    method virtual net : Eio.Net.t
    method virtual handler : handler

    method virtual run
        : Eio.Net.listening_socket -> Eio.Net.connection_handler -> unit

    method virtual stop : unit
  end

let make ?(max_connections = Int.max_int) ?additional_domains ~on_error
    (clock : #Eio.Time.clock) (net : #Eio.Net.t) handler =
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

class virtual routed_server =
  object (_ : 'a)
    inherit t
    method virtual router : Response.server_response Router.t
    method virtual add_route : 'f. Method.t -> 'f request_target -> 'f -> 'a
  end

let routed_server ?(max_connections = Int.max_int) ?additional_domains ~on_error
    (clock : #Eio.Time.clock) (net : #Eio.Net.t) (handler : handler) =
  let stop, stop_r = Eio.Promise.create () in
  let run =
    Eio.Net.run_server ~max_connections ?additional_domains ~stop ~on_error
  in
  object
    val router = Router.empty
    method clock = (clock :> Eio.Time.clock)
    method net = (net :> Eio.Net.t)
    method handler = handler
    method run = run
    method stop = Eio.Promise.resolve stop_r ()
    method router = router

    method add_route : type f.
        Method.t -> f request_target -> f -> #routed_server =
      fun meth rt f -> {<router = Router.add meth rt f router>}
  end

let get rt f (t : #routed_server) =
  let t = (t :> routed_server) in
  t#add_route Method.get rt f

let head rt f (t : #routed_server) =
  let t = (t :> routed_server) in
  t#add_route Method.head rt f

let delete rt f (t : #routed_server) =
  let t = (t :> routed_server) in
  t#add_route Method.delete rt f

let post rt f (t : #routed_server) =
  let t = (t :> routed_server) in
  t#add_route Method.post rt f

let put rt f (t : #routed_server) =
  let t = (t :> routed_server) in
  t#add_route Method.put rt f

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
