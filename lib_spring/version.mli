(** [t] is HTTP version [(major, minor)] *)
type t = private int * int

val make : major:int -> minor:int -> t

val http1_1 : t

val http1_0 : t

val equal : t -> t -> bool

val to_string : t -> string

val pp : Format.formatter -> t -> unit

val p : t Buf_read.parser
