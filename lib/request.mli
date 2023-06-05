(** [Request] is a HTTP Request. *)

(** [t] is a common request abstraction for {!type:server_request} and
    {!type:client_request}. *)

type resource = string
(** [resource] is the request uri path *)

class virtual t :
  Version.t
  -> Header.t
  -> Method.t
  -> resource
  -> object
       inherit Header.headerable
       method version : Version.t
       method meth : Method.t
       method resource : resource
       method virtual pp : Format.formatter -> unit
     end

type host_port = string * int option
(** [host_port] is a tuple of [(host, Some port)]. *)

val version : #t -> Version.t
(** [version t] is the HTTP version of request [t]. *)

val headers : #t -> Header.t
(** [headers t] is headers associated with request [t]. *)

val meth : #t -> Method.t
(** [meth t] is request method for [t].*)

val resource : #t -> string
(** [resource] is request resource uri for [t], e.g. "/home/products/123". *)

val supports_chunked_trailers : #t -> bool
(** [supports_chunked_trailers t] is [true] is request [t] has header "TE:
    trailers". It is [false] otherwise. *)

val keep_alive : #t -> bool
(** [keep_alive t] is [true] if [t] has header "Connection: keep-alive" or if
    "Connection" header is missing and the HTTP version is 1.1. It is [false] if
    header "Connection: close" exists. *)

val find_cookie : string -> #t -> string option
(** [find_cookie cookie_name t] is [Some cookie_value] if a Cookie with name
    [cookie_name] exists in [t]. Otherwise is [None]. *)

(** {1 Client Request}

    A HTTP client_request request that is primarily constructed and used by
    {!module:Client}. *)
class virtual client_request :
  Version.t
  -> Header.t
  -> Method.t
  -> resource
  -> object
       inherit t
       inherit Body.writable
       method virtual host : string
       method virtual port : int option
     end

val client_request :
     ?version:Version.t
  -> ?headers:Header.t
  -> ?port:int
  -> host:string
  -> resource:string
  -> Method.t
  -> #Body.writable
  -> client_request
(** [client_request ~host ~resource meth body] is an instance of
    {!class:client_request} where [body] is a {!class:Body.writer}. *)

val client_host_port : #client_request -> host_port
(** [client_host_port r] is the [host] and [port] for client_request request
    [r]. *)

val add_cookie : name:string -> value:string -> (#client_request as 'a) -> 'a
(** [add_cookie ~name ~value t] is [t] with cookie pair [name,value] added to
    [t]. *)

val remove_cookie : string -> (#client_request as 'a) -> 'a
(** [remove_cookie name t] is [t] with cookie pair with name [name] removed from
    [t]. *)

type url = string
(** [url] is a HTTP URI value with host information.

    {[
      "www.example.com/products"
    ]} *)

val get : url -> client_request
(** [get url] is a client_request request [r] configured with HTTP request
    method {!val:Method.Get}.

    {[
      let r = Request.get "www.example.com/products/a/"
    ]}
    @raise Invalid_argument if [url] is invalid. *)

val head : url -> client_request
(** [head url] is a client_request request [r] configured with HTTP request
    method {!val:Method.Head}.

    {[
      let r = Request.head "www.example.com/products/"
    ]}
    @raise Invalid_argument if [url] is invalid. *)

val post : (#Body.writable as 'a) -> url -> client_request
(** [post body url] is a client_request request [r] configured with HTTP request
    method {!val:Method.Post} and with request body [body]. A header
    "Content-Length" is added with suitable value in the request header.

    {[
      let body = Body.conten_writer ~content:"Hello, World!" ~content_type:"text/plain" in
      let r = Request.post body "www.example.com/product/purchase/123"
    ]}
    @raise Invalid_argument if [url] is invalid. *)

val post_form_values : (string * string list) list -> url -> client_request
(** [post_form_values form_fields url] is a client_request request [r]
    configured with HTTP request method {!val:Method.Post}. The body
    [form_fields] is a list of form fields [(name, values)]. [form_fields] is
    percent encoded before being transmitted. Two HTTP headers are added to the
    request: "Content-Length" and "Content-Type" with value
    "application/x-www-form-urlencoded".

    {[
      let form_fields = [ ("field1", [ "a"; "b" ]) ] in
      Request.post_form_values form_fields "www.example.com/product/update"
    ]}
    @raise Invalid_argument if [url] is invalid. *)

val write : #client_request -> Eio.Buf_write.t -> unit
(** [write r buf_write] writes client_request request [r] using [buf_write]. *)

(** {1 Server Request} *)

(** [server_request] is a request that is primarily constructed and used in
    {!module:Server}.

    A [server_request] is also a sub-type of {!class:Body.readable}. *)
class virtual server_request :
  Version.t
  -> Header.t
  -> Method.t
  -> resource
  -> object ('a)
       inherit t
       inherit Body.readable
       method session_data : Session.session_data option
       method add_session_data : name:string -> value:string -> unit
       method find_session_data : string -> string option
       method virtual client_addr : Eio.Net.Sockaddr.stream
     end

val buf_read : #server_request -> Eio.Buf_read.t
(** [buf_read r] is a buffered reader that can read request [r] body. *)

val client_addr : #server_request -> Eio.Net.Sockaddr.stream
(** [client_addr r] is the remote client address for request [r]. *)

val add_session_data : name:string -> value:string -> #server_request -> unit
(** [add_session_data ~name ~value t] adds session value [value] with name
    [name] to [t]. If session data with [name] already exists in [t], then the
    old value is replaced with [value].

    {b Note} This function is not thread-safe as it mutates [t], so ensure this
    function is called in a thread-safe manner if the same request instance [t]
    is being shared across OCaml domains or sys-threads. *)

val find_session_data : string -> #server_request -> string option
(** [find_session_data name t] is [Some v] is session data with name [name]
    exists in [t]. Otherwise it is [None]. *)

val session_data : #server_request -> Session.session_data option
(** [session_data t] is [Some v] if session_data exists in [t]. It is otherwise
    [None]. *)

val server_request :
     ?version:Version.t
  -> ?headers:Header.t
  -> resource:string
  -> Method.t
  -> Eio.Net.Sockaddr.stream
  -> Eio.Buf_read.t
  -> server_request
(** [server_request meth client_addr buf_read] is an instance of
    {!class:server_request}. *)

val parse : Eio.Net.Sockaddr.stream -> Eio.Buf_read.t -> server_request
(** [parse client_addr buf_read] parses a server request [r] given a buffered
    reader [buf_read]. *)

(** {1 Pretty Printer} *)

val pp : Format.formatter -> #t -> unit
