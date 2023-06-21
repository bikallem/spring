(** [Response] A HTTP Response. *)

(** [t] is a common response abstraction for response types
    {!class:server_response} and {!class:client_response}. *)
class virtual t :
  Version.t
  -> Header.t
  -> Status.t
  -> object ('a)
       method headers : Header.t
       method version : Version.t
       method status : Status.t
       method update : Header.t -> 'a
     end

val version : #t -> Version.t
(** [version t] is HTTP version of response [t]. *)

val headers : #t -> Header.t
(** [headers t] is HTTP headers for response [t]. *)

val status : #t -> Status.t
(** [status t] is HTTP status code for response [t]. *)

val find_set_cookie : string -> #t -> Set_cookie.t option
(** [find_set_cookie name t] is [Some v] if HTTP [Set-Cookie] header with name
    [name] exists in [t]. It is [None] otherwise. *)

(** {1 Client Response} *)

exception Closed

class virtual client_response :
  Version.t
  -> Header.t
  -> Status.t
  -> Eio.Buf_read.t
  -> object
       inherit t
       inherit Body.readable
       method buf_read : Eio.Buf_read.t
       method body_closed : bool
       method close_body : unit
     end

val parse : Eio.Buf_read.t -> Version.t * Header.t * Status.t
(** [parse buf_read] parses reponse [version,headers,status] from [buf_read]. *)

val close_body : #client_response -> unit
(** [close response] closes the response body of [response]. Once the [response]
    body is closed subsequent calls to read the [response] body will result in
    raising {!exception:Closed}. *)

val body_closed : #client_response -> bool
(** [closed response] is [true] if [response] is closed. [false] otherwise. *)

(** {1 Server Response} *)

module Server : sig
  type t = private
    { version : Version.t
    ; status : Status.t
    ; headers : Header.t
    ; body : Body.writable
    }

  val make :
       ?version:Version.t
    -> ?status:Status.t
    -> ?headers:Header.t
    -> Body.writable
    -> t

  val find_set_cookie : string -> t -> Set_cookie.t option
  (** [find_set_cookie name t] is [Some v] if HTTP [Set-Cookie] header with name
      [name] exists in [t]. It is [None] otherwise. *)

  val add_set_cookie : Set_cookie.t -> t -> t
  (** [add_set_cookie set_cookie t] is [t] with HTTP [Set-Cookie] header
      [set_cookie] added to it. *)

  val remove_set_cookie : string -> t -> t
  (** [remove_set_cookie name t] is [t] after removing HTTP [Set-Cookie] header
      with name [name] from [t]. *)

  val text : string -> t
  (** [text s] returns a HTTP/1.1, 200 status response with "Content-Type"
      header set to "text/plain" and "Content-Length" header set to a suitable
      value. *)

  val html : string -> t
  (** [html t s] returns a HTTP/1.1, 200 status response with header set to
      "Content-Type: text/html" and "Content-Length" header set to a suitable
      value. *)

  val ohtml : Ohtml.t -> t
  (** [ohtml view] is an Ohtml [view] based HTTP 200 server response. Its
      [Content-Type] header is set to [text/html]. *)

  val chunked_response :
       ua_supports_trailer:bool
    -> Chunked.write_chunk
    -> Chunked.write_trailer
    -> t
  (** [chunked_response ~ua_supports_trailer write_chunk write_trailer] is a
      HTTP chunked response.

      See {!module:Chunked_body}. *)

  val not_found : t
  (** [not_found] returns a HTTP/1.1, 404 status response. *)

  val internal_server_error : t
  (** [internal_server_error] returns a HTTP/1.1, 500 status response. *)

  val bad_request : t
  (* [bad_request] returns a HTTP/1.1, 400 status response. *)

  val write : Eio.Buf_write.t -> t -> unit
  (** [write t buf_write] writes server response [t] using [buf_write]. *)

  val pp : Format.formatter -> t -> unit
end

(** {1 Pretty Printer} *)

val pp : Format.formatter -> #t -> unit
