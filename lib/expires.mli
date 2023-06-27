(** [Expires] HTTP header as specified in

    https://www.rfc-editor.org/rfc/rfc9111#field.expires. *)

type t
(** [t] represents a Expires HTTP header value. A valid [t] holds date value
    that is conformant with HTTP datetime format. An expired value holds non
    conformant HTTP datetime value.

    See {{!https://www.rfc-editor.org/rfc/rfc9110#field.date} HTTP date time}. *)

val decode : string -> t
(** [decode v] decodes string [v] into a valid expires value [t]. *)

val encode : t -> string
(** [encode t] converts [t] into a string representation *)

val expired : t
(** [expired] is an expired value. It is encoded as "-1". *)

val is_expired : t -> bool
(** [is_expired t] is [true] if [t] is an expired value. [false] otherwise. An
    expired value [t] has an invalid HTTP date value. *)

val ptime : t -> Ptime.t option
(** [ptime t] is [Some ptime] if [t] holds a valid HTTP date time value. It is
    [None] otherwise. *)
