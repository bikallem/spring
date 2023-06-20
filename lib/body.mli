(** [Body] is HTTP request or response body. *)

(** {1 Writable} *)

(** [writable] is a body that can be written. *)
class virtual writable :
  object
    method virtual write_body : Eio.Buf_write.t -> unit

    method virtual write_header :
      < f : 'a. 'a Header.header -> 'a -> unit > -> unit
  end

type writable' =
  { write_body : Eio.Buf_write.t -> unit
  ; write_headers : Eio.Buf_write.t -> unit
  }

(** {2 none} *)

(** [none] is a no-op [writable] that represents the absence of HTTP request or
    response body, for e.g. http GET. HEAD, OPTIONS request.

    See {!type:Method.t} and {!class:Request.server_request}. *)
class virtual none :
  object
    inherit writable
  end

val none : none
(** [none] is an instance of {!class:none}. *)

val none' : writable'

(** {2 Content Writer} *)

val content_writer : Content_type.t -> string -> writable
(** [content_writer content_type content] creates a {!class:writable}
    request/response body whose content is [content] and content type is
    [content_type]. *)

val content_writer' : Content_type.t -> string -> writable'

val form_values_writer : (string * string list) list -> writable
(** [form_values_writer key_values] is a {!class:writer} which writes an
    associated list [key_values] as body and adds HTTP header [Content-Length]
    to HTTP request or response. *)

val form_values_writer' : (string * string list) list -> writable'

(** {1 Readable} *)

(** [readable] is a request/response body that can be read.

    {!class:Request.server_request} and {!class:Response.client_response} are
    both [readable] body types. As such both of them can be used with functions
    that accept [#readable] instances.

    {!val:read_content} and {!val:read_form_values} are readers that can read
    these values. *)
class virtual readable :
  object
    method virtual headers : Header.t
    method virtual buf_read : Eio.Buf_read.t
  end

(** {1 Readers} *)

val read_content : #readable -> string option
(** [read_content readable] is [Some content], where [content] is of length [n]
    if "Content-Length" header is a valid integer value [n] in [readable].

    If ["Content-Length"] header is missing or is an invalid value in [readable]
    then [None] is returned. *)

val read_form_values : #readable -> (string * string list) list
(** [read_form_values readable] is [form_values] if [readable] body
    [Content-Type] is ["application/x-www-form-urlencoded"] and [Content-Length]
    is a valid integer value.

    [form_values] is a list of tuple of form [(name, values)] where [name] is
    the name of the form field and [values] is a list of values corresponding to
    the [name]. *)
