(** [Te] implements TE header specification at
    https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.4 *)

type directive

type q = string
(** [q] is the q value as specified at
    https://httpwg.org/specs/rfc9110.html#rfc.section.12.4.2 *)

type t
(** [t] holds TE header values. *)

(** {1 Directives} *)

val directive : string -> directive
(** [directive name] is [directive]. *)

val trailers : directive
val compress : directive
val deflate : directive
val gzip : directive

(** {1 Exists, Add/Remove} *)

val exists : t -> directive -> bool
val add : ?q:q -> t -> directive -> t
val get_q : t -> directive -> q option
val remove : t -> directive -> t

(** {1 Iter} *)

val iter : (directive -> q option -> unit) -> t -> unit

(** {1 Codec} *)

val encode : t -> string
val decode : string -> t
