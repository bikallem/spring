(** [Content_disposition] implements [Content-Disposition] header as specified
    in https://httpwg.org/specs/rfc6266.html#top *)

type t
type disposition = string

val make : ?params:(string * string) list -> disposition -> t
val decode : string -> t
val encode : t -> string
val disposition : t -> string
val find_param : t -> string -> string option
