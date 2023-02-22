type directive = [ `trailers | `compress of q | `deflate of q | `gzip of q ]
and q = string option

type t

val exists : directive -> t -> bool
val add : directive -> t -> t
val remove : directive -> t -> t
val iter : (directive -> unit) -> t -> unit
val encode : t -> string
val decode : string -> t
