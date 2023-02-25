(** [Content_type] implements "Content-Type" header value encoding/decoding as
    specified in https://httpwg.org/specs/rfc9110.html#rfc.section.8.3 *)

(** [t] is the HTTP [Content-Type] header value. *)
type t

(** [media_type] is a tuple of [(type, subtype)]. e.g. text/plain, text/html,
    multipart/formdata etc.

    See https://httpwg.org/specs/rfc9110.html#rfc.section.8.3.1 *)
type media_type = string * string

(** [make media_type] is [t].

    @param params is the list of parameters encoded in [t]. Default is [\[\]]. *)
val make : ?params:(string * string) list -> media_type -> t

(** {1 Codec} *)

(** [decode v] decodes [v] into [t].

    {i example} Decode a following content type header:
    [Content-Type: multipart/form-data; boundary=------------------3862150; charset="utf-8"]

    {[
      Content_type.decode
        "multipart/form-data; boundary=------------------3862150; \
         charset=\"utf-8\""
    ]} *)
val decode : string -> t

(** [encode t] encodes [t] into a string. *)
val encode : t -> string

(** {1 Media Type, Charset} *)

(** [media_type t] is the media type of [t]. *)
val media_type : t -> media_type

(** [charset t] is [Some charset] if a character encoding is provided in [t]. It
    is [None] otherwise.

    [charset] is the textual character encoding scheme in [t], e.g.
    [charset=utf8]. [charset] value is case-insensitive.

    See https://httpwg.org/specs/rfc9110.html#rfc.section.8.3.2 *)
val charset : t -> string option

(** {1 Params} *)

(** [find_param t param] is [Some v] is [param] exists in [t]. It is [None]
    otherwise. *)
val find_param : t -> string -> string option
