(** [Cookie] implements HTTP Cookie header functionality as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

type t
(** [t] represents a HTTP cookie. A cookie can hold 1 or more values indexed via
    a case-sensitive cookie name. *)

val decode : string -> t
(** [decode s] decodes [s] into [t]. *)

val encode : t -> string

(** {1 Find Cookies} *)

val find : t -> string -> string option
(** [find t cookie_name] is [Some v] if [cookie_name] exists in [t]. It is
    [None] otherwise. *)
