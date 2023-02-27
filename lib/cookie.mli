(** [Cookie] implements HTTP Cookie header functionality as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

(** [t] represents a HTTP cookie. *)
type t = (string * string) list

val decode : string -> t
