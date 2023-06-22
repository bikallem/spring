(** [Server] is a HTTP 1.1 server. *)

(** {1 Handler} *)

type handler = Request.Server.t -> Response.Server.t
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

val router_pipeline : Response.Server.t Router.t -> pipeline
(** [router_pipeline router] is a pipeline which multiplexes incoming requests
    based on [router]. *)

val session_pipeline : #Session.codec -> pipeline
(** [session_pipeline session] is a pipeline implementing HTTP request session
    functionality in spring. *)

(** {1 Servers}*)

type 'a t
(** [t] represents a HTTP/1.1 server instance configured with some specific
    server parameters. *)

type http
(** [http] is a raw HTTP/1.1 server without any configured pipeline. *)

val make_http_server :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> on_error:(exn -> unit)
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> handler
  -> http t
(** [make_http_server ~on_error clock net handler] is [t].

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

type app
(** [app] is a HTTP/1.1 server with the following pipelines preconfigured for
    convenience:

    - [strict_http]
    - [session_pipeline]
    - [router_pipeline] *)

val empty_app : app

val make_app_server :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> ?handler:handler
  -> ?session_codec:#Session.codec
  -> ?master_key:string
  -> on_error:(exn -> unit)
  -> secure_random:#Eio.Flow.source
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> app
  -> app t
(** [make_app_server t ~secure_random ~on_error clock net] is {!type:app} [t].

    @param handler
      specifies handler to be added after [router_pipeline] is executed. The
      default value is {!val:not_found_handler}
    @param session_codec
      is the session codec implementation to be used by the [app t]. The default
      value is [Session.cookie_codec].
    @param master_key
      is a randomly generated unique key which is used to decrypt/encrypt data.
      If a value is not provided, it is set to a value from one of the options
      below:

      - environment variable [___SPRING_MASTER_KEY___]
      - file [master.key]
    @param csrf_token_name
      is the form field name which holds the anticsrf token value. The default
      value is "__csrf_token__".
    @param secure_random
      in the OS dependent secure random number generator. It is usually
      [Eio.Stdenv.secure_random]. *)

type 'a request_target = ('a, Response.Server.t) Router.request_target

val get : 'f request_target -> 'f -> app -> app
(** [get request_target f t] is [t] with a route that matches HTTP GET method
    and [request_target] *)

val head : 'f request_target -> 'f -> app -> app
(** [head request_target f t] is [t] with a route that matches HTTP HEAD method
    and [request_target]. *)

val delete : 'f request_target -> 'f -> app -> app
(** [delete request_target f t] is [t] with a route that matches HTTP DELETE
    method and [request_target]. *)

val post : 'f request_target -> 'f -> app -> app
(** [post request_target f t] is [t] with a route that matches HTTP POST method
    and [request_target]. *)

val put : 'f request_target -> 'f -> app -> app
(** [put request_target f t] is [t] with a route that matches HTTP PUT method
    and [request_target]. *)

val add_route : Method.t -> 'f request_target -> 'f -> app -> app
(** [add_route meth request_target f t] adds route made from
    [meth],[request_target] and [f] to [t]. *)

(** {1 Running Servers} *)

val run : Eio.Net.listening_socket -> _ t -> unit
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
  ?reuse_addr:bool -> ?socket_backlog:int -> ?port:int -> _ t -> unit
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

val shutdown : _ t -> unit
(** [shutdown t] instructs [t] to stop accepting new connections and waits for
    inflight connections to complete. *)
