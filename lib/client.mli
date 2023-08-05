(** HTTP/1.1 client.

    [Client] implements connection reuse based on [host] and [port] attributes
    of a HTTP/1.1 connection.

    See {{!common} for common client use cases}. *)

type t
(** [t] is a HTTP client. It encapsulates client buffered reader/writer initial
    sizes, timeout settings for HTTP client calls, and connection reuse
    functionality.

    It is safe for concurrent usage.

    See {!val:make}. *)

val make :
     ?timeout:Eio.Time.Timeout.t
  -> ?read_initial_size:int
  -> ?write_initial_size:int
  -> ?maximum_conns_per_host:int
  -> Eio.Switch.t
  -> #Eio.Net.t
  -> t
(** [make sw net] is [t]. [net] is used to create/establish connections to
    remote HTTP/1.1 server.

    [sw] is the client resource manager for [t]. All connections are added to
    [sw] upon creation and automatically closed when [sw] goes out of scope or
    is cancelled. [t] does not outlive [sw]. Attempting to use [t] outside of
    scope of [sw] is an error. However, this is not enforced statically by the
    type system.

    @param timeout
      is the total time limit for establishing a connection, making a request
      and getting a response back from the server. However, this value doesn't
      include reading response body. Default is [Eio.Time.Timeout.none].
    @param read_initial_size
      is the initial client buffered reader size. Default is [0x1000].
    @param write_initial_size
      is the initial client buffered writer size. Default is [0x1000].
    @param max_conns_per_host
      is the maximum number of connections cached per host,port. The default is
      [5]. *)

(** {1:common Common Client Use-Cases}

    Common client use-cases optimized for convenience. *)

type uri = string
(** [uri] is the full HTTP request uri. [http://www.example.com/products] or
    [wwww.example.com/products].

    If HTTP uri scheme - [http/htttps] - is not given, then [http] is assumed. *)

type request = Request.client Request.t

type response = Response.client Response.t

type 'a handler = response -> 'a
(** [handler] is the response handler. [Response.close] is called after
    executing the [handler]. *)

val get : t -> uri -> 'a handler -> 'a
(** [get t uri] is [response] after making a HTTP GET request call to [uri].

    {[
      Client.get t "www.example.com"
    ]}
    @raise Invalid_argument if [uri] is invalid.
    @raise Eio.Exn.Io in cases of connection errors. *)

val head : t -> uri -> 'a handler -> 'a
(** [head t uri] is [response] after making a HTTP HEAD request call to [uri].

    {[
      Client.head t "www.example.com"
    ]}
    @raise Invalid_argument if [uri] is invalid.
    @raise Eio.Exn.Io in cases of connection errors. *)

val post : t -> Body.writable -> uri -> 'a handler -> 'a
(** [post t body uri] is [response] after making a HTTP POST request call with
    body [body] to [uri].

    {[
      Client.port t body_w "www.example.com/update"
    ]}
    @raise Invalid_argument if [uri] is invalid.
    @raise Eio.Exn.Io in cases of connection errors. *)

val post_form_values :
  t -> (string * string list) list -> uri -> 'a handler -> 'a
(** [post_form_values t form_values uri] is [response] after making a HTTP POST
    request call to [uri] with form values [form_values].

    {[
      Client.post_form_values t
        [ ("field_a", [ "val a1"; "val a2" ]); ("field_b", [ "val b" ]) ]
        uri
    ]}
    @raise Invalid_argument if [uri] is invalid.
    @raise Eio.Exn.Io in cases of connection errors. *)

(** {1 Generic Client Call} *)

val do_call : t -> request -> 'a handler -> 'a
(** [do_call t req] makes a HTTP request using [req] and returns
    {!type:response}.

    @raise Eio.Exn.Io in cases of connection errors. *)

val call : conn:#Eio.Flow.two_way -> request -> response
(** [call conn req] makes a HTTP client call using connection [conn] and request
    [req]. It returns a {!type:response} upon a successfull call.

    {i Note} The function doesn't use connection cache or implement request
    redirection or cookie functionality.

    @raise Eio.Exn.Io in cases of connection errors. *)

(** {1 Client Configuration} *)

val buf_write_initial_size : t -> int
(** [buf_write_initial_size] is the buffered writer iniital size. *)

val buf_read_initial_size : t -> int
(** [buf_read_initial_size] is the buffered reader initial size. *)

val timeout : t -> Eio.Time.Timeout.t
(** [timeout] specifies total time limit for establishing a connection, calling
    a request and getting a response back.

    A client request is cancelled if the specified timeout limit is exceeded. *)
