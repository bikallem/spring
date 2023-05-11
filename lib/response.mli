(** [Response] A HTTP Response. *)

(** [t] is a common response abstraction for response types
    {!class:server_response} and {!class:client_response}. *)
class virtual t :
  Version.t
  -> Header.t
  -> Status.t
  -> object ('a)
       inherit Header.headerable
       method version : Version.t
       method status : Status.t
     end

val version : #t -> Version.t
(** [version t] is HTTP version of response [t]. *)

val headers : #t -> Header.t
(** [headers t] is HTTP headers for response [t]. *)

val status : #t -> Status.t
(** [status t] is HTTP status code for response [t]. *)

val add_header : 'a Header.header -> 'a -> (#t as 't) -> 't
(** [add_header] is [Header.add_header]. *)

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

class virtual server_response :
  Version.t
  -> Header.t
  -> Status.t
  -> object
       inherit t
       inherit Body.writable
     end

val server_response :
     ?version:Version.t
  -> ?headers:Header.t
  -> ?status:Status.t
  -> #Body.writable
  -> server_response
(** [server_response body] is a server response with body [body]. *)

val add_set_cookie : Set_cookie.t -> (#server_response as 'a) -> 'a
(** [add_set_cookie set_cookie t] is [t] with HTTP [Set-Cookie] header
    [set_cookie] added to it. *)

val chunked_response :
     ua_supports_trailer:bool
  -> Chunked.write_chunk
  -> Chunked.write_trailer
  -> server_response
(** [chunked_response ~ua_supports_trailer write_chunk write_trailer] is a HTTP
    chunked response.

    See {!module:Chunked_body}. *)

val write : #server_response -> Eio.Buf_write.t -> unit
(** [write response buf_write] writes server response [response] using
    [buf_write]. *)

val text : string -> server_response
(** [text s] returns a HTTP/1.1, 200 status response with "Content-Type" header
    set to "text/plain" and "Content-Length" header set to a suitable value. *)

val html : string -> server_response
(** [html t s] returns a HTTP/1.1, 200 status response with header set to
    "Content-Type: text/html" and "Content-Length" header set to a suitable
    value. *)

val ohtml : Ohtml.t -> server_response
(** [ohtml view] is an Ohtml [view] based HTTP 200 server response. Its
    [Content-Type] header is set to [text/html]. *)

val not_found : server_response
(** [not_found] returns a HTTP/1.1, 404 status response. *)

val internal_server_error : server_response
(** [internal_server_error] returns a HTTP/1.1, 500 status response. *)

val bad_request : server_response
(* [bad_request] returns a HTTP/1.1, 400 status response. *)

(** {1 Pretty Printer} *)

val pp : Format.formatter -> #t -> unit
