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

(** [head] is HTTP HEAD method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.2 *)
val head : t

(** [delete] is HTTP DELETE method as defined in
    https://httpwg.org/specs/rfc9110.html#DELETE *)
val delete : t

(** [options] is HTTP OPTIONS method as defined in
    https://httpwg.org/specs/rfc9110.html#OPTIONS *)
val options : t

(** [trace] is HTTP TRACE method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.8 *)
val trace : t

(** [post] is HTTP POST method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.3 *)
val post : t

(** [put] is HTTP PUT method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.4 *)
val put : t

(** [patch] is HTTP PATCH method as defined in
    https://www.rfc-editor.org/rfc/rfc5789 *)
val patch : t

(** [connect] is HTTP CONNECT method as defined in
    https://httpwg.org/specs/rfc9110.html#CONNECT *)
val connect : t

(** {1 Pretty Printers} *)

(** [to_string t] is the textual representation of [t] in ASCII lowercase form. *)
val to_string : t -> lowercase_string

(** [equal a b] is [true] if both [a] and [b] represent the same HTTP request
    method value. *)
val equal : t -> t -> bool

val pp : Format.formatter -> t -> unit
