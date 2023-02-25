(** [Te] implements TE header specification at
    https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.4 *)

type directive

(** [q] is the q value as specified at
    https://httpwg.org/specs/rfc9110.html#rfc.section.12.4.2 *)
type q = string

(** [t] holds TE header values. *)
type t

(** {1 Directives} *)

(** [directive name] is [directive]. *)
val directive : string -> directive

val trailers : directive

val compress : directive

val deflate : directive

val gzip : directive

(** {1 Exists, Add/Remove} *)

val singleton : ?q:q -> directive -> t

val exists : t -> directive -> bool

val add : ?q:q -> t -> directive -> t

val get_q : t -> directive -> q option

val remove : t -> directive -> t

(** {1 Iter} *)

val iter : (directive -> q option -> unit) -> t -> unit

(** {1 Codec} *)

val encode : t -> string

val decode : string -> t
