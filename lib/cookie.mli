(** [Cookie] implements HTTP Cookie header functionality as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

type t
(** [t] represents a HTTP cookie. A cookie can hold one or more values indexed via
    a case-sensitive cookie name. *)

val decode : string -> t
(** [decode s] decodes [s] into [t]. *)

val encode : t -> string
(** [encode t] encodes [t] into a string representation. *)

val find : t -> string -> string option
(** [find t cookie_name] is [Some v] if [cookie_name] exists in [t]. It is
    [None] otherwise. *)

val add : name:string -> value:string -> t -> t
(** [add ~name ~value t] adds a cookie [name] and [value] pair to [t] *)
