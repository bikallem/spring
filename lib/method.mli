type lowercase_string = private string

type t = lowercase_string

val make : string -> t

module M : sig
  val get : t

  val head : t

  val delete : t

  val options : t

  val trace : t

  val post : t

  val put : t

  val patch : t

  val connect : t
end

include module type of M

val to_string : t -> lowercase_string

val equal : t -> t -> bool

val pp : Format.formatter -> t -> unit
