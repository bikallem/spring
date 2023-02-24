(** [Content_type] implements "Content-Type" header value encoding/decoding as
    specified in https://httpwg.org/specs/rfc9110.html#rfc.section.8.3 *)

type t
(** [t] is the HTTP [Content-Type] header value. *)

(** {1 Codec} *)

val decode : string -> t
(** [decode v] decodes [v] into [t].

    {i example} Decode a following content type header:
    [Content-Type: multipart/form-data; boundary=------------------3862150; charset="utf-8"]

    {[
      Content_type.decode
        "multipart/form-data; boundary=------------------3862150; \
         charset=\"utf-8\""
    ]} *)

(** {1 Media Type, Charset} *)

val media_type : t -> string * string
(** [media_type t] is the media type of [t], e.g. text/plain, text/html,
    multipart/formdata etc.

    See https://httpwg.org/specs/rfc9110.html#rfc.section.8.3.1 *)

val charset : t -> string option
(** [charset t] is [Some charset] if a character encoding is provided in [t]. It
    is [None] otherwise.

    [charset] is the textual character encoding scheme in [t], e.g.
    [charset=utf8]. [charset] value is case-insensitive.

    See https://httpwg.org/specs/rfc9110.html#rfc.section.8.3.2 *)

(** {1 Params} *)

val find_param : t -> string -> string option
