(** [Server] is a HTTP 1.1 server. *)

(** {1 Handler} *)

type request = Request.server Request.t

type response = Response.server Response.t

type handler = request -> response
(** [handler] responds to HTTP request by returning a HTTP response. *)

val not_found_handler : handler
(** [not_found_handler] return HTTP 404 response. *)

(** {1 Pipeline}*)

type pipeline = handler -> handler
(** [pipeline] is a combinator for combining one or more HTTP request handlers.

    The type [pipeline] is equivalent to a longer form
    [fun next_handler req -> response ].

    We can generally combine one of more [pipelines] using OCaml infix function,
    [@@].

    {b Usage}

    [router] below is an example [pipeline] that routes incoming request based
    on request [resource] value. It only handles ["/"] resource path and any
    other values are delegated to the [next] handler. Note we use [@@] to
    combine [router] pipeline with the builtin handler {!val:not_found_handler}.

    {[
      let router : Server.pipeline =
       fun next req ->
        match Request.resource req with
        | "/" -> Response.text "hello, there"
        | _ -> next req

      let make_handler _t = router @@ Server.not_found_handler

      let () =
        Eio_main.run @@ fun env ->
        Server.make ~on_error:raise ~secure_random:env#secure_random
          ~make_handler env#clock env#net
        |> Server.run_local
    ]}

    The handlers are executed in the order they are combined, i.e. first the
    [router] is executed then the [Server.not_found_handler]. *)

val host_header : pipeline
(** [host_header_pipeline] validates an incoming request for valid "Host" header
    value. RFC 9112 states that host is required in server requests and server
    MUST send bad request if Host header value is not correct.

    https://www.rfc-editor.org/rfc/rfc9112#section-3.2 *)

val response_date : #Eio.Time.clock -> pipeline
(* [response_date clock] adds "Date" header to responses if required.

   https://www.rfc-editor.org/rfc/rfc9110#section-6.6.1 *)

val router_pipeline : response Router.t -> pipeline
(** [router_pipeline router] is a pipeline which multiplexes incoming requests
    based on [router]. *)

val session_pipeline : Session.codec -> pipeline
(** [session_pipeline session] is a pipeline implementing HTTP request session
    functionality in spring. *)

(** {1 Servers}*)

type t
(** [t] represents a HTTP/1.1 server instance configured with some specific
    server parameters. *)

type make_handler = t -> handler
(** [make_handler] makes a HTTP request handler from [t]. *)

val default_make_handler : make_handler
(** [default_make_handler] is a [make_handler] with the following pipelines and
    handlers preconfigured :

    - {{!val:response_date} Response Date}
    - {{!val:host_header} Host Header}
    - {{!val:session_pipeline} Session Pipeline}
    - {{!val:router_pipeline} Router Pipeline}
    - {{!val:not_found_handler} Not Found Handler} *)

val clock : t -> Eio.Time.clock
(** [clock t] is the eio clock implementation used by [t]. It is usually
    [Eio.Stdenv.t#clock]. *)

val net : t -> Eio.Net.t
(** [net t] is the network interface used by [t]. It is usually
    [Eio.Stdenv.t#net]. *)

val master_key : t -> string
(** [master_key t] is a 32 bytes long value used to decrypt/encrypt sensitive
    data. The value can be read from a specific file [master.key] or an
    environment variable [__SPRING_MASTER_KEY__]. *)

val session_codec : t -> Session.codec option
(** [session_codec t] is the [Some session_codec] if [t] is initialized with a
    session codec. Otherwise it is [None]. *)

val make_handler : t -> make_handler
(** [make_handler t] is the [make_handler] function used by [t]. *)

val router : t -> response Router.t
(** [router t] is the router used by [t]. *)

val make :
     ?max_connections:int
  -> ?additional_domains:#Eio.Domain_manager.t * int
  -> ?make_handler:make_handler
  -> ?session_codec:Session.codec
  -> ?master_key:string
  -> on_error:(exn -> unit)
  -> secure_random:#Eio.Flow.source
  -> #Eio.Time.clock
  -> #Eio.Net.t
  -> t
(** [make ~secure_random ~on_error clock net] is a HTTP server [t].

    {b Running a Parallel Server:} By default [t] runs on a {e single} OCaml
    {!module:Domain}. However, if [additional_domains:(domain_mgr, domains)]
    parameter is given, then [t] will spawn [domains] additional domains and run
    accept loops in those too. In such cases you must ensure that request
    handlers only accesses thread-safe values. Note that having more than
    {!Domain.recommended_domain_count} domains in total is likely to result in
    bad performance.

    @param max_connections
      The maximum number of concurrent connections accepted by [t] at any time.
      The default is [Int.max_int].

    @param additional_domains
      denotes the setting for running server [t] in multiple domains.
    @param make_handler
      is the {!type:make_handler}. Default is {!val:default_make_handler}.
    @param session_codec
      is the session codec implementation to be used by the [t]. The default
      value is [Session.cookie_codec].
    @param master_key
      is a randomly generated unique key which is used to decrypt/encrypt data.
      If a value is not provided, it is read from one of the sources below
      below:

      - environment variable [___SPRING_MASTER_KEY___]
      - file [master.key]. The [master.key] file can be generated using
        [spring.exe key] command.
    @param secure_random
      in the OS dependent secure random number generator. It is usually
      [Eio.Stdenv.secure_random]. *)

type 'a request_target = ('a, response) Router.request_target
(** [request_target] is the request path for router. Use [spring] ppx and
    [[%r ]] syntax to add routes to a router. *)

val get : 'f request_target -> 'f -> t -> t
(** [get request_target f t] is [t] with a route that matches HTTP GET method
    and [request_target] *)

val head : 'f request_target -> 'f -> t -> t
(** [head request_target f t] is [t] with a route that matches HTTP HEAD method
    and [request_target]. *)

val delete : 'f request_target -> 'f -> t -> t
(** [delete request_target f t] is [t] with a route that matches HTTP DELETE
    method and [request_target]. *)

val post : 'f request_target -> 'f -> t -> t
(** [post request_target f t] is [t] with a route that matches HTTP POST method
    and [request_target]. *)

val put : 'f request_target -> 'f -> t -> t
(** [put request_target f t] is [t] with a route that matches HTTP PUT method
    and [request_target]. *)

val add_route : Method.t -> 'f request_target -> 'f -> t -> t
(** [add_route meth request_target f t] adds route made from
    [meth],[request_target] and [f] to [t]. *)

(** {2 File Server} *)

val serve_dir :
     on_error:(exn -> response)
  -> dirpath:_ Eio.Path.t
  -> (string -> request -> response) request_target
  -> t
  -> t
(** [serve_dir ~on_error ~dirpath route_url t] adds static file serving
    capability to HTTP server [t]. [t] serves static files located in directory
    path [dirpath] in response to requests with request path matching url value
    [route_url].

    Use ppx [[%r "" ]] to specify [route_url]. See {{!section:usage} Usage}.

    [t] will respond with [Response.not_found] if a file requested in
    [route_url] doesn't exist in [dirpath].

    {:file_server_caching Caching Headers}

    [t] adds HTTP caching headers [Last-Modified], [ETag], [Expires] and
    [Cache-Control] to responses.

    {:file_server_conditional Conditional Requests}

    [t] responds to conditional requests with [If-None-Match] and
    [If-Modified-Since] headers. If both are present, then [If-None-Match] is
    given preference as it is more accurate than [If-Modified-Since].

    {:usage Usage}

    Serve files in local directory "./public" - non recursively, i.e. url path
    such as ["/public/style.css" , "/public/a.js", "/public/a.html"] etc.

    {[
      let () =
        Eio_main.run @@ fun env ->
        let dirpath = Eio.Path.(env#fs / "./public") in
        Server.make ~on_error:raise ~secure_random:env#secure_random env#clock
          env#net
        |> Server.serve_dir ~on_error:raise ~dirpath [%r "/public/:string"]
    ]}

    Serve files in local directory "./public/" recursively, i.e. serve files in
    url path
    ["/public/css/a.css" "/public/css/b.css", "/public/js/a.js",  "/public/js/b.js"]

    {[
      let () =
        Eio_main.run @@ fun env ->
        let dirpath = Eio.Path.(env#fs / "./public") in
        Server.make ~on_error:raise ~secure_random:env#secure_random env#clock
          env#net
        |> Server.serve_dir ~on_error:raise ~dirpath [%r "/public/**"]
    ]}
    @param on_error
      error handler that is called when [t] encounters an error - other than the
      not found error - while reading files in [dirpath] *)

val serve_file :
     on_error:(exn -> response)
  -> filepath:_ Eio.Path.t
  -> (request -> response) request_target
  -> t
  -> t

(** {1 Running Servers} *)

val run : Eio.Net.listening_socket -> t -> unit
(** [run socket t] runs a HTTP/1.1 server [t] listening on socket [socket]. *)

val run_local :
  ?reuse_addr:bool -> ?socket_backlog:int -> ?port:int -> t -> unit
(** [run_local t] runs HTTP/1.1 server [t] on a local TCP/IP address
    [localhost].

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

val shutdown : t -> unit
(** [shutdown t] instructs [t] to stop accepting new connections and waits for
    inflight connections to complete and finally stops server [t]. *)
