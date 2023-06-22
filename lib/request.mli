(** [Request] is a HTTP Request. *)

(** [t] is a common request abstraction for {!type:server_request} and
    {!type:client_request}. *)

type resource = string
(** [resource] is the request uri path *)

type 'a t = private
  { meth : Method.t
  ; resource : resource
  ; version : Version.t
  ; headers : Header.t
  ; x : 'a
  ; pp : Format.formatter -> 'a t -> unit
  }

val supports_chunked_trailers : _ t -> bool
(** [supports_chunked_trailers t] is [true] is request [t] has header "TE:
    trailers". It is [false] otherwise. *)

val keep_alive : _ t -> bool
(** [keep_alive t] is [true] if [t] has header "Connection: keep-alive" or if
    "Connection" header is missing and the HTTP version is 1.1. It is [false] if
    header "Connection: close" exists. *)

val find_cookie : string -> _ t -> string option
(** [find_cookie cookie_name t] is [Some cookie_value] if a Cookie with name
    [cookie_name] exists in [t]. Otherwise is [None]. *)

(** {1 Client Request}

    A HTTP client request. This is primarily constructed and used by
    {!module:Client}. *)

type client = private { host : string; port : int option; body : Body.writable }

val make_client_request :
     ?version:Version.t
  -> ?headers:Header.t
  -> ?port:int
  -> host:string
  -> resource:resource
  -> Method.t
  -> Body.writable
  -> client t
(** [make ~host ~resource meth body] is [t] representing a client request with
    request url [resource]. [host] represents a HTTP server that will process
    [t]. [meth] is the HTTP request method. [body] is the request body.

    @param version HTTP version of [t]. Default is [1.1].
    @param headers HTTP request headers of [t]. Default is [Header.empty] .
    @param port the [host] port. Default is [None]. *)

val add_cookie : name:string -> value:string -> client t -> client t
(** [add_cookie ~name ~value t] is [t] with cookie pair [name,value] added to
    [t]. *)

val remove_cookie : string -> client t -> client t
(** [remove_cookie name t] is [t] with cookie pair with name [name] removed from
    [t]. *)

val write_client_request : client t -> Eio.Buf_write.t -> unit
(** [write t buf_write] writes [t] to [buf_write]. *)

(** {1 Server Request}

    [Server.t] is a HTTP request that is primarily constructed and used in
    {!module:Server}. *)

type server = private
  { client_addr : Eio.Net.Sockaddr.stream
  ; buf_read : Eio.Buf_read.t
  ; mutable session_data : Session.session_data option
  }

val make_server_request :
     ?version:Version.t
  -> ?headers:Header.t
  -> ?session_data:Session.session_data
  -> resource:resource
  -> Method.t
  -> Eio.Net.Sockaddr.stream
  -> Eio.Buf_read.t
  -> server t
(** [make_server_request meth client_addr buf_read] is HTTP request [t].

    @param version HTTP version of [t]. Default is [1.1].
    @param headers HTTP request headers of [t]. Default is [Header.empty] .
    @param session_data is the Session data for the request. Default is [None]. *)

val add_session_data : name:string -> value:string -> server t -> unit
(** [add_session_data ~name ~value t] adds session value [value] with name
    [name] to [t]. If session data with [name] already exists in [t], then the
    old value is replaced with [value].

    {b Note} This function is not thread-safe as it mutates [t], so ensure this
    function is called in a thread-safe manner if the same request instance [t]
    is being shared across OCaml domains or sys-threads. *)

val replace_session_data : Session.session_data -> server t -> unit
(** [replace_context_session_data session_data t] is [t] with session data in
    [t] replaced by [session_data]. After this operation
    [session_data t = Some session_data]. *)

val find_session_data : string -> server t -> string option
(** [find_session_data name t] is [Some v] is session data with name [name]
    exists in [t]. Otherwise it is [None]. *)

val to_readable : server t -> Body.readable
(** [to_readable t] converts [t] to {!type:Body.readable}. *)

val parse_server_request :
     ?session:#Session.codec
  -> Eio.Net.Sockaddr.stream
  -> Eio.Buf_read.t
  -> server t
(** [parse client_addr buf_read] parses a server request [r] given a buffered
    reader [buf_read]. *)

(** {1 Pretty Printer} *)

val pp : Format.formatter -> _ t -> unit

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
    -> resource:resource
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
