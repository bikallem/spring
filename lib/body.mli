(** HTTP request and response body. *)

(** {1 Writable}

    Request/Response body that can be written. *)

type writable
(** [writable] encapsulates a specific mechanism to write a request/response
    body. *)

val make_writable :
     write_body:(Eio.Buf_write.t -> unit)
  -> write_headers:(Eio.Buf_write.t -> unit)
  -> writable
(** [make_writable ~write_body ~write_headers] creates a writable [body].

    [write_body] writes he reqeust/response [body].

    [write_headers] writes headers associated with [body] *)

val none : writable
(** [none] is a no-op [writable] that represents the absence of HTTP request or
    response body, for e.g. http GET. HEAD, OPTIONS request. *)

val write_body : Eio.Buf_write.t -> writable -> unit
(** [write_body buf_write body] writes [body] onto [buf_write]. *)

val write_headers : Eio.Buf_write.t -> writable -> unit
(** [write_headers buf_write body] writes [body] onto [buf_write]. *)

(** {2 Common Writable Bodies}

    Request/Response bodies that can be written.

    Additional [writable] bodies :

    + {{!section:Chunked.writable} Writable HTTP Chunked Body}
    + {{!section:Multipart.writable} Writable Multipart/Form Body} *)

val writable_content : Content_type.t -> string -> writable
(** [writable_content content_type content] is a fixed-length writable [body]
    with content [content].

    [content_type] denotes the type of [content] encoded in [body]. It manifests
    in HTTP request/response [Content-Type] header. *)

val writable_form_values : (string * string list) list -> writable
(** [writable_form_values key_values] is a writable [body] which encodes a form
    submission content. Its [Content-Type] header is encoded as
    "application/x-www.form-urlencoded". *)

(** {1 Readable} *)

type readable
(** [readable] is a request/response body that can be read.

    See {!val:Request.readable} and {!val:Response.readable}. *)

val make_readable : Header.t -> Eio.Buf_read.t -> readable
(** [make_readable headers buf_read] makes a readable body from [headers] and
    [buf_read]. *)

val headers : readable -> Header.t
(** [headers r] is HTTP headers {!type:Header.t} associated with readable body
    [r]. *)

val buf_read : readable -> Eio.Buf_read.t
(** [buf_read r] is buffered reader {!type:Eio.Buf_read.t} associated with
    readable body [r]. *)

(** {2:readers Readers}

    Some common request/response readers.

    Additional readers :

    + {{!section:Multipart.streaming} Multipart Streaming}
    + {{!section:Multipart.form} Multipart Form}
    + {{!section:Chunked.reader} Reading HTTP Chunked Body} *)

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
