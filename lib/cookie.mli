(** [Cookie] implements HTTP Cookie header functionality as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

(** [t] represents a HTTP cookie. *)
type t

val decode : string -> t

val find : t -> string -> string option
