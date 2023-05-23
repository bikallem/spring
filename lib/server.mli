(** [Server] is a HTTP 1.1 server. *)

(** {1 Handler} *)

type handler = Request.server_request -> Response.server_response
(** [handler] is a HTTP request handler. *)

val not_found_handler : handler
(** [not_found_handler] return HTTP 404 response. *)

(** {1 Pipeline}*)

type pipeline = handler -> handler
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

val host_header : pipeline
(** [host_header_pipeline] validates an incoming request for valid "Host" header
    value. RFC 9112 states that host is required in server requests and server
    MUST send bad request if Host header value is not correct.

    https://www.rfc-editor.org/rfc/rfc9112#section-3.2 *)

val response_date : #Eio.Time.clock -> pipeline
(* [response_date clock] adds "Date" header to responses if required.

   https://www.rfc-editor.org/rfc/rfc9110#section-6.6.1 *)

val strict_http : #Eio.Time.clock -> pipeline
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

val router_pipeline : Response.server_response Router.t -> pipeline
(** [router_pipeline router] is a pipeline which multiplexes incoming requests
    based on [router]. *)

val cookie_session : cookie_name:string -> key:string -> pipeline
(** [cookie_session ~cookie_name ~key] is a pipeline implementing HTTP request
    session functionality in spring. [key] is the secret key used to
    encrypt/decrypt session data. [cookie_name] is the name of the session
    cookie.

    @param cookie_name is the name of the session cookie. *)

(** {1 Servers}*)

(** [t] represents a HTTP/1.1 server instance configured with some specific
    server parameters. *)
class virtual t :
  object
    method virtual clock : Eio.Time.clock
    method virtual net : Eio.Net.t
    method virtual handler : handler

    method virtual run :
      Eio.Net.listening_socket -> Eio.Net.connection_handler -> unit

    method virtual stop : unit
  end

val make :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> on_error:(exn -> unit)
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> handler
  -> t
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

type 'a request_target = ('a, Response.server_response) Router.request_target

(** [app_server] is a HTTP/1.1 web server with the following pipelines
    preconfigured for convenience:

    - [router_pipeline]
    - [strict_http] *)
class virtual app_server :
  session_cookie_name:string
  -> object ('a)
       inherit t
       method session_cookie_name : string
       method virtual router : Response.server_response Router.t
       method virtual add_route : Method.t -> 'f request_target -> 'f -> 'a
     end

val app_server :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> ?handler:handler
  -> ?session_cookie_name:string
  -> ?master_key:string
  -> on_error:(exn -> unit)
  -> secure_random:#Eio.Flow.source
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> app_server
(** [app_server ~on_error clock net] is an [app_server].

    @param handler
      specifies handler to be added after [router_pipeline] is executed. The
      default value is {!val:not_found_handler} *)

val get : 'f request_target -> 'f -> #app_server -> app_server
(** [get request_target f t] is [t] with a route that matches HTTP GET method
    and [request_target] *)

val head : 'f request_target -> 'f -> #app_server -> app_server
(** [head request_target f t] is [t] with a route that matches HTTP HEAD method
    and [request_target]. *)

val delete : 'f request_target -> 'f -> #app_server -> app_server
(** [delete request_target f t] is [t] with a route that matches HTTP DELETE
    method and [request_target]. *)

val post : 'f request_target -> 'f -> #app_server -> app_server
(** [post request_target f t] is [t] with a route that matches HTTP POST method
    and [request_target]. *)

val put : 'f request_target -> 'f -> #app_server -> app_server
(** [put request_target f t] is [t] with a route that matches HTTP PUT method
    and [request_target]. *)

val add_route : Method.t -> 'f request_target -> 'f -> #app_server -> app_server
(** [add_route meth request_target f t] adds route made from
    [meth],[request_target] and [f] to [t]. *)

(** {1 Running Servers} *)

val run : Eio.Net.listening_socket -> #t -> unit
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

val run_local :
  ?reuse_addr:bool -> ?socket_backlog:int -> ?port:int -> #t -> unit
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

val connection_handler :
  handler -> #Eio.Time.clock -> Eio.Net.connection_handler
(** [connection_handler handler clock] is a connection handler, suitable for
    passing to {!Eio.Net.accept_fork}. *)

val shutdown : #t -> unit
(** [shutdown t] instructs [t] to stop accepting new connections and waits for
    inflight connections to complete. *)
