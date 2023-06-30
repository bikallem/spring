(** HTTP [Expires] response header as specified in

    https://www.rfc-editor.org/rfc/rfc9111#field.expires. *)

type t
(** [t] represents a [Expires] HTTP header value which holds a HTTP Date
    timestamp value.

    See {{!https://www.rfc-editor.org/rfc/rfc9110#field.date} HTTP Date
    timestamp}. *)

val expired : t
(** [expired] is an expired value. It is encoded as "0".

    See {{!https://www.rfc-editor.org/rfc/rfc9111#section-5.3-7} 'expired'
    encoding}. *)

val is_expired : t -> bool
(** [is_expired t] is [true] if [t] is an expired value. [false] otherwise. An
    expired value [t] has an invalid HTTP date value. *)

(** {1 HTTP Date Timestamp} *)

val date : t -> Date.t option
(** [date t] is [Some date] if [t] holds a valid HTTP date time value. It is
    [None] otherwise. *)

(** {1 Codec} *)

val decode : string -> t
(** [decode v] decodes string [v] into a valid expires value [t].

    Invalid [v] represents an {!val:expired} value. *)

val encode : t -> string
(** [encode t] converts [t] into a string representation *)

(** {1 Pretty Printer} *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
