(** [Cookie] implements HTTP Cookie header functionality as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

(** [t] represents a HTTP cookie. *)
type t

val decode : string -> t

(** [find t cookie_name] is [Some v] if [cookie_name] exists in [t]. It is
    [None] otherwise. *)
val find : t -> string -> string option
