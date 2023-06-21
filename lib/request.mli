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
  -> object ('a)
       method headers : Header.t
       method version : Version.t
       method meth : Method.t
       method resource : resource
       method update : Header.t -> 'a
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

    A HTTP client request. This is primarily constructed and used by
    {!module:Client}. *)

module Client : sig
  type t = private
    { meth : Method.t
    ; resource : resource
    ; version : Version.t
    ; headers : Header.t
    ; host : string
    ; port : int option
    ; body : Body.writable
    }

  val make :
       ?version:Version.t
    -> ?headers:Header.t
    -> ?port:int
    -> host:string
    -> resource:string
    -> Method.t
    -> Body.writable
    -> t
  (** [make ~host ~resource meth body] is [t] representing a client request with
      request url [resource]. [host] represents a HTTP server that will process
      [t]. [meth] is the HTTP request method. [body] is the request body.

      @param version HTTP version of [t]. Default is [1.1].
      @param headers HTTP request headers of [t]. Default is [Header.empty] .
      @param port the [host] port. Default is [None]. *)

  val supports_chunked_trailers : t -> bool
  (** [supports_chunked_trailers t] is [true] is request [t] has header "TE:
      trailers". It is [false] otherwise. *)

  val keep_alive : t -> bool
  (** [keep_alive t] is [true] if [t] has header "Connection: keep-alive" or if
      "Connection" header is missing and the HTTP version is 1.1. It is [false]
      if header "Connection: close" exists. *)

  val find_cookie : string -> t -> string option
  (** [find_cookie cookie_name t] is [Some cookie_value] if a Cookie with name
      [cookie_name] exists in [t]. Otherwise is [None]. *)

  val add_cookie : name:string -> value:string -> t -> t
  (** [add_cookie ~name ~value t] is [t] with cookie pair [name,value] added to
      [t]. *)

  val remove_cookie : string -> t -> t
  (** [remove_cookie name t] is [t] with cookie pair with name [name] removed
      from [t]. *)

  val write : t -> Eio.Buf_write.t -> unit
  val pp : Format.formatter -> t -> unit
end

(** {1 Server Request} *)

(** [server_request] is a request that is primarily constructed and used in
    {!module:Server}.

    A [server_request] is also a sub-type of {!class:Body.readable}. *)
class virtual server_request :
  ?session_data:Session.session_data
  -> Version.t
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
  -> ?session_data:Session.session_data
  -> resource:string
  -> Method.t
  -> Eio.Net.Sockaddr.stream
  -> Eio.Buf_read.t
  -> server_request
(** [server_request meth client_addr buf_read] is an instance of
    {!class:server_request}. *)

val parse :
     ?session:#Session.codec
  -> Eio.Net.Sockaddr.stream
  -> Eio.Buf_read.t
  -> server_request
(** [parse client_addr buf_read] parses a server request [r] given a buffered
    reader [buf_read].

    @param session_cookie_name is the name of the session cookie. *)

(** {1 Pretty Printer} *)

val pp : Format.formatter -> #t -> unit
