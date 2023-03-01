(** [Response] A HTTP Response. *)

(** [t] is a common response abstraction for response types
    {!class:server_response} and {!class:client_response}. *)
class virtual t :
  object
    method virtual version : Version.t

    method virtual headers : Header.t

    method virtual status : Status.t
  end

(** [version t] is HTTP version of response [t]. *)
val version : #t -> Version.t

(** [headers t] is HTTP headers for response [t]. *)
val headers : #t -> Header.t

(** [status t] is HTTP status code for response [t]. *)
val status : #t -> Status.t

(** {1 Client Response} *)

exception Closed

class client_response :
  Version.t
  -> Header.t
  -> Status.t
  -> Eio.Buf_read.t
  -> object
       inherit t

       inherit Body.readable

       method version : Version.t

       method headers : Header.t

       method status : Status.t

       method buf_read : Eio.Buf_read.t

       method body_closed : bool

       method close_body : unit
     end

(** [parse buf_read] parses reponse [version,headers,status] from [buf_read]. *)
val parse : Eio.Buf_read.t -> Version.t * Header.t * Status.t

(** [close response] closes the response body of [response]. Once the [response]
    body is closed subsequent calls to read the [response] body will result in
    raising {!exception:Closed}. *)
val close_body : #client_response -> unit

(** [closed response] is [true] if [response] is closed. [false] otherwise. *)
val body_closed : #client_response -> bool

(** {1 Server Response} *)

class virtual server_response :
  object
    inherit t

    inherit Body.writable
  end

(** [server_response body] is a server response with body [body]. *)
val server_response :
     ?version:Version.t
  -> ?headers:Header.t
  -> ?status:Status.t
  -> #Body.writable
  -> server_response

(** [chunked_response ~ua_supports_trailer write_chunk write_trailer] is a HTTP
    chunked response.

    See {!module:Chunked_body}. *)
val chunked_response :
     ua_supports_trailer:bool
  -> Chunked.write_chunk
  -> Chunked.write_trailer
  -> server_response

(** [write response buf_write] writes server response [response] using
    [buf_write]. *)
val write : #server_response -> Eio.Buf_write.t -> unit

(** [text s] returns a HTTP/1.1, 200 status response with "Content-Type" header
    set to "text/plain" and "Content-Length" header set to a suitable value. *)
val text : string -> server_response

(** [html t s] returns a HTTP/1.1, 200 status response with header set to
    "Content-Type: text/html" and "Content-Length" header set to a suitable
    value. *)
val html : string -> server_response

(** [not_found] returns a HTTP/1.1, 404 status response. *)
val not_found : server_response

(** [internal_server_error] returns a HTTP/1.1, 500 status response. *)
val internal_server_error : server_response

val bad_request : server_response
(* [bad_request] returns a HTTP/1.1, 400 status response. *)

(** {1 Pretty Printer} *)

val pp : Format.formatter -> #t -> unit