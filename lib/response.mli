(** [Response] A HTTP Response. *)

type 'a t
(** [t] is a HTTP response. *)

val version : _ t -> Version.t
val status : _ t -> Status.t
val headers : _ t -> Header.t

val find_set_cookie : string -> _ t -> Set_cookie.t option
(** [find_set_cookie name t] is [Some v] if HTTP [Set-Cookie] header with name
    [name] exists in [t]. It is [None] otherwise. *)

val pp : Format.formatter -> _ t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)

(** {1 Client Response} *)

type client

val make_client_response :
     ?version:Version.t
  -> ?status:Status.t
  -> ?headers:Header.t
  -> Eio.Buf_read.t
  -> client t

val parse_client_response : Eio.Buf_read.t -> client t
(** [parse_client_response buf_read] parses [buf_read] and create HTTP reponse
    [t]. *)

exception Closed

val buf_read : client t -> Eio.Buf_read.t
(** [buf_read t] is buffered reader associated with [t].

    @raise Closed if [t] is already closed. *)

val closed : client t -> bool
(** [closed response] is [true] if [response] is closed. [false] otherwise. *)

val close : client t -> unit
(** [close response] closes the response body of [response]. Once the [response]
    body is closed subsequent calls to read the [response] body will result in
    raising {!exception:Closed}. *)

val to_readable : client t -> Body.readable
(** [to_readable t] converts [t] to {!type:Body.readable}. *)

(** {1 Server Response} *)

type server

val make_server_response :
     ?version:Version.t
  -> ?status:Status.t
  -> ?headers:Header.t
  -> Body.writable
  -> server t

val body : server t -> Body.writable
(** [body t] is a response body associated with [t]. *)

val add_set_cookie : Set_cookie.t -> server t -> server t
(** [add_set_cookie set_cookie t] is [t] with HTTP [Set-Cookie] header
    [set_cookie] added to it. *)

val remove_set_cookie : string -> server t -> server t
(** [remove_set_cookie name t] is [t] after removing HTTP [Set-Cookie] header
    with name [name] from [t]. *)

val text : string -> server t
(** [text s] returns a HTTP/1.1, 200 status response with "Content-Type" header
    set to "text/plain" and "Content-Length" header set to a suitable value. *)

val html : string -> server t
(** [html t s] returns a HTTP/1.1, 200 status response with header set to
    "Content-Type: text/html" and "Content-Length" header set to a suitable
    value. *)

val ohtml : Ohtml.t -> server t
(** [ohtml view] is an Ohtml [view] based HTTP 200 server response. Its
    [Content-Type] header is set to [text/html]. *)

val chunked_response :
     ua_supports_trailer:bool
  -> Chunked.write_chunk
  -> Chunked.write_trailer
  -> server t
(** [chunked_response ~ua_supports_trailer write_chunk write_trailer] is a HTTP
    chunked response.

    See {!module:Chunked_body}. *)

val not_found : server t
(** [not_found] returns a HTTP/1.1, 404 status response. *)

val internal_server_error : server t
(** [internal_server_error] returns a HTTP/1.1, 500 status response. *)

val bad_request : server t
(* [bad_request] returns a HTTP/1.1, 400 status response. *)

val write_server_response : Eio.Buf_write.t -> server t -> unit
(** [write_server_response t buf_write] writes server response [t] using
    [buf_write]. *)
