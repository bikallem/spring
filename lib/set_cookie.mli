(** [Set_cookie] implements HTTP [Set-Cooki]e header functionality as specified
    in https://www.rfc-editor.org/rfc/inline-errata/rfc6265.html *)

(** [t] represents a HTTP cookie. *)
type t

val decode : string -> t

(** {1 Cookie Attributes} *)

val name : t -> string

val value : t -> string

val expires : t -> Ptime.t option

val max_age : t -> int option

val domain : t -> [ `raw ] Domain_name.t option

val path : t -> string option

val secure : t -> bool

val http_only : t -> bool

val extensions : t -> string list

(** {1 Expire a Cookie} *)

(** [expire t] configures [t] to be expired/removed by user-agents. *)
val expire : t -> t
