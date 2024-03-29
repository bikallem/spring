(** [Method] implements HTTP request method as specified in
    https://httpwg.org/specs/rfc9110.html#methods *)

type lowercase_string = private string

type t = lowercase_string
(** [t] represents an instance of HTTP request method. Its textual
    representation is an ASCII lowercase string. *)

val make : string -> t
(** [make meth] creates a HTTP request method [t] represented by [meth]. *)

(** {1 Methods} *)

val get : t
(** [get] is HTTP GET method as defined in
    https://httpwg.org/specs/rfc9110.html#GET *)

val head : t
(** [head] is HTTP HEAD method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.2 *)

val delete : t
(** [delete] is HTTP DELETE method as defined in
    https://httpwg.org/specs/rfc9110.html#DELETE *)

val options : t
(** [options] is HTTP OPTIONS method as defined in
    https://httpwg.org/specs/rfc9110.html#OPTIONS *)

val trace : t
(** [trace] is HTTP TRACE method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.8 *)

val post : t
(** [post] is HTTP POST method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.3 *)

val put : t
(** [put] is HTTP PUT method as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.9.3.4 *)

val patch : t
(** [patch] is HTTP PATCH method as defined in
    https://www.rfc-editor.org/rfc/rfc5789 *)

val connect : t
(** [connect] is HTTP CONNECT method as defined in
    https://httpwg.org/specs/rfc9110.html#CONNECT *)

(** {1 Pretty Printers} *)

val to_string : t -> lowercase_string
(** [to_string t] is the textual representation of [t] in ASCII lowercase form. *)

val equal : t -> t -> bool
(** [equal a b] is [true] if both [a] and [b] represent the same HTTP request
    method value. *)

val pp : Format.formatter -> t -> unit
