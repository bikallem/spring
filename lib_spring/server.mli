(** [Server] is a HTTP 1.1 server. *)

(** [t] represents a HTTP/1.1 server instance configured with some specific
    server parameters. *)
type t

(** [handler] is a HTTP request handler. *)
type handler = Request.server_request -> Response.server_response

(** [pipeline] is the HTTP request processsing pipeline. It is usually used with
    OCaml infix function, [@@].

    [router] below is an example [pipeline] that routes incoming request based
    on request [resource] value. It only handles ["/"] resource path and any
    other values are delegated to the [next] handler.

    {[
      let router : Server.pipeline =
       fun next req ->
        match Request.resource req with
        | "/" -> Response.text "hello, there"
        | _ -> next req

      let handler : Server.handler = router @@ Server.not_found_handler

      let () =
        Eio_main.run @@ fun env ->
        let server = Server.make ~on_error:raise env#clock env#net handler in
        Server.run_local server
    ]}

    The [handler] handler demonstrates how various [pipeline]s can be
    constructed and used with {!val:make}. The handlers are executed in the
    order they are combined, i.e. first the [router] is executed then the
    [Server.not_found_handler]. *)
type pipeline = handler -> handler

(** [host_header_pipeline] validates an incoming request for valid "Host" header
    value. RFC 9112 states that host is required in server requests and server
    MUST send bad request if Host header value is not correct.

    https://www.rfc-editor.org/rfc/rfc9112#section-3.2 *)
val host_header : pipeline

val response_date : #Eio.Time.clock -> pipeline
(* [response_date clock] adds "Date" header to responses if required.

   https://www.rfc-editor.org/rfc/rfc9110#section-6.6.1 *)

(** [strict_http] is a convenience pipeline that include both {!val:host_header}
    and {!val:response_date} pipeline. The pipeline intends to more strictly
    follow the relevant HTTP specifictions.

    Use this pipeline as your base [pipeline] along with your [handler] if you
    enforce HTTP standards in a strict and conforming manner.

    {[
      let app _req = Response.text "hello world"

      let () =
        Eio_main.run @@ fun env ->
        let handler = Server.strict_http env#clock @@ app in
        let server = Server.make ~on_error:raise env#clock env#net handler in
        Server.run_local server
    ]} *)
val strict_http : #Eio.Time.clock -> pipeline

(** [make ~on_error clock net handler] is [t].

    {b Running a Parallel Server} By default [t] runs on a {e single} OCaml
    {!module:Domain}. However, if [additional_domains:(domain_mgr, domains)]
    parameter is given, then [t] will spawn [domains] additional domains and run
    accept loops in those too. In such cases you must ensure that [handler] only
    accesses thread-safe values. Note that having more than
    {!Domain.recommended_domain_count} domains in total is likely to result in
    bad performance.

    @param max_connections
      The maximum number of concurrent connections accepted by [t] at any time.
      The default is [Int.max_int]. *)
val make :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> on_error:(exn -> unit)
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> handler
  -> t

(** [run socket t] runs a HTTP/1.1 server listening on socket [socket].

    {[
      Eio_main.run @@ fun env ->
      Eio.Switch.run @@ fun sw ->
      let addr = Eio.Net.Ipaddr.of_raw "2606:2800:220:1:248:1893:25c8:1946" in
      let socket = Eio.Net.listen ~backlog:5 ~sw env#net (`Tcp (addr, 80)) in
      let handler _req = Cohttp_eio.Response.text "hello world" in
      let server = Server.make ~on_error:raise env#clock handler in
      Cohttp_eio.Server.run socket server
    ]} *)
val run : Eio.Net.listening_socket -> t -> unit

(** [run_local t] runs server on TCP/IP address [localhost] and by default on
    port [80].

    {[
      Eio_main.run @@ fun env ->
      let handler _req = Cohttp_eio.Response.text "hello world" in
      let server = Cohttp_eio.make ~on_error:raise env#clock env#net handler in
      Cohttp_eio.Server.run_local server
    ]}
    @param reuse_addr
      configures listening socket to reuse [localhost] address. Default value is
      [true].
    @param socket_backlog is the socket backlog value. Default is [128].
    @param port
      is the port number for TCP/IP address [localhost]. Default is [80]. *)
val run_local :
  ?reuse_addr:bool -> ?socket_backlog:int -> ?port:int -> t -> unit

(** [connection_handler handler clock] is a connection handler, suitable for
    passing to {!Eio.Net.accept_fork}. *)
val connection_handler :
  handler -> #Eio.Time.clock -> Eio.Net.connection_handler

(** [shutdown t] instructs [t] to stop accepting new connections and waits for
    inflight connections to complete. *)
val shutdown : t -> unit

(** {1 Basic Handlers} *)

(** [not_found_handler] return HTTP 404 response. *)
val not_found_handler : handler