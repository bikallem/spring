(** [Set_cookie] implements HTTP [Set-Cooki]e header functionality as specified
    in https://datatracker.ietf.org/doc/html/rfc6265

    Addtionally, the module also supports Same-Site cookie attribute value as
    specified in
    https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-cookie-same-site-00#section-1 *)

(** [t] represents a HTTP Set-Cookie header value. *)
type t

(** {1 Create} *)

type name_value = string * string

type same_site = private string

(** {1 Same Site} *)

val strict : same_site

val lax : same_site

(** {1 Create} *)

val make :
     ?expires:Ptime.t
  -> ?max_age:int
  -> ?domain:[ `raw ] Domain_name.t
  -> ?path:string
  -> ?secure:bool
  -> ?http_only:bool
  -> ?extensions:string list
  -> ?same_site:same_site
  -> name_value
  -> t

val decode : string -> t

val encode : t -> string

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

val same_site : t -> same_site option

(** {1 Expire a Cookie} *)

(** [expire t] configures [t] to be expired/removed by user-agents. *)
val expire : t -> t

(** {1 Pretty Printing} *)

val pp : Format.formatter -> t -> unit
