(** [Content_disposition] implements [Content-Disposition] header as specified
    in https://httpwg.org/specs/rfc6266.html#top *)

type t

val decode : string -> t
val disposition : t -> string
val find_param : t -> string -> string option
