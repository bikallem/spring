(** [Content_type] implements "Content-Type" header value encoding/decoding as
    specified in https://httpwg.org/specs/rfc9110.html#rfc.section.8.3 *)

type t

val decode : string -> t
val media_type : t -> string * string
val find_param : t -> string -> string option
