(** [Method] implements HTTP request method as specified in
    https://httpwg.org/specs/rfc9110.html#methods *)

type lowercase_string = private string

(** [t] represents an instance of HTTP request method. Its textual
    representation is an ASCII lowercase string. *)
type t = lowercase_string

(** [make meth] creates a HTTP request method [t] represented by [meth]. *)
val make : string -> t

(** {1 Methods} *)

(** [get] is HTTP GET method as defined in
    https://httpwg.org/specs/rfc9110.html#GET *)
val get : t

val head : t

val delete : t

val options : t

val trace : t

val post : t

val put : t

val patch : t

val connect : t

val to_string : t -> lowercase_string

val equal : t -> t -> bool

val pp : Format.formatter -> t -> unit
