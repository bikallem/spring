(** [Server] is a HTTP 1.1 server. *)

(** {1 Handler} *)

type request = Request.server Request.t

type response = Response.server Response.t

type handler = request -> response
(** [handler] responds to HTTP request by returning a HTTP response. *)

val not_found_handler : handler
(** [not_found_handler] return HTTP 404 response. *)

val serve_dir :
     on_error:(exn -> response)
  -> dir_path:Eio.Fs.dir Eio.Path.t
  -> string
  -> handler
(** [serve_dir ~on_error ~dir_path filepath] is a [handler] that returns a HTTP
    response containing file content pointed to by [filepath] in directory
    [dir_path].

    The handler returns [Response.not_found] if a file pointed to by [filepath]
    doesn't exist in [dir_path].

    {b Usage with [Router.t]}

    Serve files in local directory "./public" - non recursively, i.e. url path
    such as ["/public/style.css" , "/public/a.js", "/public/a.html"] etc.

    {[
      let () =
        Eio_main.run @@ fun env ->
        let serve_dir = Server.serve_dir ~dir_path:"./public" in
        Server.make ~on_error:raise ~secure_random:env#secure_random env#clock
          env#net
        |> Server.get [%r "/public/:string"] serve_dir
    ]}

    Serve files in local directory "./public/" recursively, i.e. serve files in
    url path
    ["/public/css/a.css" "/public/css/b.css", "/public/js/a.js",  "/public/js/b.js"]

    {[
      let () =
        Eio_main.run @@ fun env ->
        let serve_dir = Server.serve_dir ~dir_path:"./public" in
        Server.make ~on_error:raise ~secure_random:env#secure_random env#clock
          env#net
        |> Server.get [%r "/public/**"] serve_dir
    ]}
    @param on_error
      the error handler that is called when [handler] encounters an error while
      reading files in [dir_path] and [filepath]. *)

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
(** [default_make_handler] is a [make_handler] with the following pipelines
    preconfigured :

    - [response_date]
    - [host_header]
    - [session_pipeline]
    - [router_pipeline] *)

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
(** [make t ~secure_random ~on_error clock net handler] is a HTTP server [t].

    {b Running a Parallel Server} By default [t] runs on a {e single} OCaml
    {!module:Domain}. However, if [additional_domains:(domain_mgr, domains)]
    parameter is given, then [t] will spawn [domains] additional domains and run
    accept loops in those too. In such cases you must ensure that [handler] only
    accesses thread-safe values. Note that having more than
    {!Domain.recommended_domain_count} domains in total is likely to result in
    bad performance.

    @param max_connections
      The maximum number of concurrent connections accepted by [t] at any time.
      The default is [Int.max_int].
    @param session_codec
      is the session codec implementation to be used by the [t]. The default
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

type 'a request_target = ('a, response) Router.request_target
(** [request_target] is the request path for router. Use [spring] ppx and
    [\[%r \]] syntax to add routes to a router. *)

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
