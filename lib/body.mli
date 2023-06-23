(** HTTP request and response body. *)

(** {1 Writable} *)

type writable
(** [writable] is a body that can be written. *)

val make_writable :
     write_body:(Eio.Buf_write.t -> unit)
  -> write_headers:(Eio.Buf_write.t -> unit)
  -> writable

val none : writable
(** [none] is a no-op [writable] that represents the absence of HTTP request or
    response body, for e.g. http GET. HEAD, OPTIONS request. *)

val write_body : Eio.Buf_write.t -> writable -> unit
(** [write_body buf_write body] writes [body] onto [buf_write]. *)

val write_headers : Eio.Buf_write.t -> writable -> unit
(** [write_headers buf_write body] writes [body] onto [buf_write]. *)

(** {2 Common Writable Bodies} *)

val content_writer : Content_type.t -> string -> writable
(** [content_writer content_type content] is a request/response body.
    [content_type] denotes the body content encoded in [content]. *)

val form_values_writer : (string * string list) list -> writable
(** [form_values_writer key_values] is a request/response body which encodes a
    form submission content. The request/response [Content-Type] is
    "application/x-www.form-urlencoded". *)

(** {1 Readable} *)

type readable
(** [readable] is a request/response body that can be read.

    See {!val:Request.to_readable} and {!val:Response.to_readable}. *)

val make_readable : Header.t -> Eio.Buf_read.t -> readable
(** [make_readable headers buf_read] makes a readable body from [headers] and
    [buf_read]. *)

val headers : readable -> Header.t
(** [headers r] is HTTP headers {!type:Header.t} associated with readable body
    [r]. *)

val buf_read : readable -> Eio.Buf_read.t
(** [buf_read r] is buffered reader {!type:Eio.Buf_read.t} associated with
    readable body [r]. *)

(** {2 Common Body Readers} *)

val read_content : readable -> string option
(** [read_content readable] is [Some content], where [content] is of length [n]
    if "Content-Length" header is a valid integer value [n] in [readable].

    If ["Content-Length"] header is missing or is an invalid value, then [None]
    is returned. *)

val read_form_values : readable -> (string * string list) list
(** [read_form_values readable] is [form_values] if [readable] body
    [Content-Type] is ["application/x-www-form-urlencoded"] and [Content-Length]
    is a valid integer value.

    [form_values] is a list of tuple of form [(name, values)] where [name] is
    the name of the form field and [values] is a list of values corresponding to
    the [name]. *)
