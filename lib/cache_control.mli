(** HTTP Cache-Control header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#name-cache-control *)

(** {1:directive Directives} *)

module Directive : sig
  type 'a t
  (** [t] is a request or response cache directive. *)

  val name : 'a t -> string

  type 'a decode = string -> 'a

  type 'a encode = 'a -> string

  val decode : 'a t -> 'a decode option

  val encode : 'a t -> 'a encode option
end

val max_age : int Directive.t
(** [max_age] is [max-age] directive. It holds value [d]. [d] is time in
    seconds.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-max-age} max-age} *)

val no_cache : bool Directive.t

(** {1 Cache-Control} *)

type t
(** [t] is a HTTP [Cache-Control] header value. [t] contains one or more
    {{!section:directive} directives}. *)

val empty : t
(** [empty] is an empty [Cache-Control] value. *)

val add : ?v:'a -> 'a Directive.t -> t -> t
(** [add ?v d t] is a new Cache-Control value with directive definition [d] and
    directive value [v] added to [t]. *)

val find_opt : 'a Directive.t -> t -> 'a option
(** [find_opt d t] is [Some v] if a directive [d] exists in [t]. *)
