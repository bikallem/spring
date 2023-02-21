type 'a t

val make : string -> 'a -> 'a t
val get : Body.none t
val head : Body.none t
val delete : Body.none t
val options : Body.none t
val trace : Body.none t
val post : 'a t
val put : 'a t
val patch : 'a t
val connect : Body.none t
val equal : 'a t -> 'b t -> bool
val name : 'a t -> string
val pp : Format.formatter -> 'a t -> unit
