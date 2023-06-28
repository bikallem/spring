(** HTTP ETag header value as specified in
    https://www.rfc-editor.org/rfc/rfc9110#field.etag *)

type t
(** [t] is a valid [ETag] header value. *)

val make : ?weak:bool -> string -> t
(** [make s] creates [ETag] value [t] from [s]. [s] is validated to ensure only
    valid [ETag] characters are present.

    @param weak
      if [true] then a weak [ETag] value is created. Default is [false].
    @raise Invalid_arg if [s] contains invalid [ETag] characters. *)

val decode : string -> t
(** [decode v] decodes [v] into an [ETag] header value if [v] conforms to [ETag]
    value format. *)

val chars : t -> string
(** [chars t] is a string representing [ETag] characters in [t]. *)

val is_weak : t -> bool
(** [is_weak t] is [true] if [t] is a weak [ETag] value. Otherwise it is
    [false]. *)

val is_strong : t -> bool
(** [is_strong t] is [true] if [t] is a strong [ETag] value. Otherwise it is
    [false]. *)

type equal = t -> t -> bool
(** [equal] is an [ETag] comparison function. *)

val strong_equal : equal
(** [strong_equal a b] applies
    {{!https://datatracker.ietf.org/doc/html/rfc7232#section-2.3.2} Strong}
    comparison to determine if etag values [a] and [b] are the same. *)

val weak_equal : equal
(** [weak_equal a b] applies
    {{!https://datatracker.ietf.org/doc/html/rfc7232#section-2.3.2} Weak}
    comparison to determine if etag values [a] and [b] are the same. *)

val encode : t -> string
(** [encode t] encodes [t] to a string. *)

val parse : consume:[ `All | `Prefix ] -> Buf_read.t -> t
(** [parse ~consume buf_read] decodes [t] from [buf_read].

    [consume = `All] denotes that [buf_read] must be fully read when [t] is
    decoded.

    [consume = `Prefix] denotes that [buf_read] can contain additional data when
    [t] is decoded.

    @raise Invalid_arg
      if [consume = `All] and [buf_read] is not at the end of input. *)
