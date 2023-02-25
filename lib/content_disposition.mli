(** [Content_disposition] implements [Content-Disposition] header as specified
    in https://httpwg.org/specs/rfc6266.html#top *)

type t

val make : ?params:(string * string) list -> string -> t
val decode : string -> t
val encode : t -> string
val disposition : t -> string
val find_param : t -> string -> string option
