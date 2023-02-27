(** [Set_cookie] implements HTTP [Set-Cooki]e header functionality as specified
    in https://www.rfc-editor.org/rfc/inline-errata/rfc6265.html *)

(** [t] represents a HTTP cookie. *)
type t

val decode : string -> t

(** {1 Cookie Attributes} *)

val name : t -> string

val value : t -> string

val expires : t -> Ptime.t option
