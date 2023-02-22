type directive
type q = string
type t

val trailers : directive
val compress : directive
val deflate : directive
val gzip : directive
val exists : t -> directive -> bool
val add : ?q:q -> t -> directive -> t
val get_q : t -> directive -> q option
val remove : t -> directive -> t
val iter : (directive -> q option -> unit) -> t -> unit
val encode : t -> string
val decode : string -> t
