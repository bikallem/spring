(** [Server] is a HTTP 1.1 server. *)

(** {1 Handler} *)

type handler = Context.t -> Response.server_response
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

val session_pipeline : #Session.t -> pipeline
(** [session_pipeline session] is a pipeline implementing HTTP request session
    functionality in spring. *)

val anticsrf_pipeline :
  protected_http_methods:Method.t list -> anticsrf_token_name:string -> pipeline
(** [anticsrf_pipeline ~protected_http_methods ~anticsrf_token_name] is a
    pipeline implementing CSRF protection mechanism in [Spring].

    The CSRF protection method employed by the pipeline is
    {b Synchronizer Token Pattern}. This is described in detail at
    https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#synchronizer-token-pattern

    In order to use AntiCSRF protection in [Spring] applications, a developer
    must first generate [anticsrf-token] using
    {!val:Context.init_anticsrf_token} and {!val:Context.anticsrf_token}
    functions.

    The [anticsrf-token] should then be used as follows:

    First, in a [hidden] HTML form field value. The field name is as specified
    by [anticsrf_token_name]. This is to be done by the user/developer in
    perhaps a [.ohtml] view. For example like so below:

    {[
      <form action="/transfer.do" method="post">
      <input type="hidden" name="__anticsrf_token__" value="OWY4NmQwODE4ODRjN2Q2NTlhMmZlYWEwYzU1YWQwMTVhM2JmNGYxYjJiMGI4MjJjZDE1ZDZMGYwMGEwOA==">
      ...
      </form>
    ]}

    {b Note} When using [multipart/formdata] in a HTML form, ensure that this
    field is the first defined field in the form. The pipeline expects the
    [anticsrf-token] field to be the first one.

    Secondly, the [anticsrf-token] value is then added to the session storage
    via request context [Context.session_data ctx]. The session field name is
    [anticsrf_token_name]. Populating the session is done by the pipeline itself
    so a developer input is not needed for this step.

    During request processing, the pipeline retrieves the [anticsrf-token] value
    from the above two objects and validates that they are the same. A
    [Bad Request] response is sent if this is not so.

    Lastly, the pipeline only protects requests against CSRF attacks when the
    request HTTP methods is one of the methods specified in
    [protected_http_methods]. *)

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

    - [session_pipeline]
    - [anticsrf_pipeline]
    - [router_pipeline]
    - [strict_http] *)
class virtual app_server :
  object ('a)
    inherit t
    method virtual session : Session.t
    method virtual router : Response.server_response Router.t
    method virtual add_route : Method.t -> 'f request_target -> 'f -> 'a
  end

val app_server :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> ?handler:handler
  -> ?session:#Session.t
  -> ?master_key:string
  -> ?anticsrf_protected_http_methods:Method.t list
  -> ?anticsrf_token_name:string
  -> on_error:(exn -> unit)
  -> secure_random:#Eio.Flow.source
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> app_server
(** [app_server ~secure_random ~on_error clock net] is an [app_server].

    @param handler
      specifies handler to be added after [router_pipeline] is executed. The
      default value is {!val:not_found_handler}
    @param session
      is the session implementation to be used by the [app_server] The default
      session implementation used is [Session.cookie_session].
    @param master_key
      is a randomly generated unique key which is used to decrypt/encrypt data.
      If a value is not provided, it is set to a value from one of the options
      below:

      - environment variable [___SPRING_MASTER_KEY___]
      - file [master.key]
    @param anticsrf_protected_http_methods
      is the list of HTTP methods that is proctected by CSRF proctection
      mechanism. The default is [Method.post; Method.put; Method.delete].
    @param anticsrf_form_field
      is the form field name which holds the anticsrf token value. The default
      value is "__anticsrf_token__".
    @param secure_random
      in the OS dependent secure random number generator. It is usually
      [Eio.Stdenv.secure_random]. *)

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
