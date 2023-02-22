type t

val http1_1 : t
val equal : t -> t -> bool
val to_string : t -> string
val pp : Format.formatter -> t -> unit
