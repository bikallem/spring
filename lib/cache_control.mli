(** HTTP Cache-Control header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#name-cache-control *)

(** {1:directive Directives} *)

module Directive : sig
  type 'a t
  (** [t] is a request or response cache directive. A directive is either a bool
      directive or not. A bool directive is one which doesn't have a
      corresponding value. *)

  val name : 'a t -> string
  (** [name t] is the name of the cache-directive [t]. *)

  val is_bool : 'a t -> bool
  (** [is_bool t] is [true] if [t] is a bool directive. *)

  type 'a decode = string -> 'a

  type 'a encode = 'a -> string

  val decode : 'a t -> 'a decode option
  (** [decode t] is [Some f] if directive [t] is not a bool directive. [f] is
      the decoder function for [t].

      It is [None] if [t] is a bool directive. *)

  val encode : 'a t -> 'a encode option
  (** [encode t] is [Some f] if directive [t] is not a bool directive. [f] is
      the encoder function for [t].

      It is [None] if [t] is a bool directive. *)
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
(** [find_opt d t] is [Some v] if directive [d] exists in [t]. [v] is value as
    denoted by [d].

    It is [None] if [d] doesn't exis in [t]. *)

val find : 'a Directive.t -> t -> 'a
(** [find d t] is [v] if directive [d] exists in [t]. [v] is the value as
    denoted by [d].

    If [Directive.is_bool d = true] then [v = true] denotes the existence of
    directive [d].

    @raise Not_found
      if [d] is not found in [t] and [Directive.is_bool d = false]. *)

val decode : string -> t
(** [decode s] decodes [s] into [t]. *)
