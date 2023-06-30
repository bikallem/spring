(** HTTP Cache-Control header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#name-cache-control *)

(** {1:directive Directives} *)

module Directive : sig
  type 'a t
  (** [t] is a cache directive, such as [no-cache, max-age=5, private] etc. *)

  val name : 'a t -> string
  (** [name t] is the name of the cache-directive [t]. *)

  val is_bool : 'a t -> bool
  (** [is_bool t] is [true] if [t] is a bool directive.

      See {!type:bool_directive}. *)

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

type bool_directive = bool Directive.t
(** [bool_directive] a cache-directive that doesn't have a corresponding value
    associated with it, e.g. [no-cache, private, public] etc.

    [max-age] is not a bool directive as it has a value associated with it.
    value.

    See {!val:Directive.is_bool}. *)

val max_age : int Directive.t
(** [max_age] is [max-age] directive. It holds value [d]. [d] is time in
    seconds.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-max-age} max-age} *)

val no_cache : bool Directive.t
(** [no_cache] is [no-cache] directive.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-no-cache} no-cache}. *)

(** {1 Cache-Control} *)

type t
(** [t] is a HTTP [Cache-Control] header value. [t] contains one or more
    {{!section:directive} directives}. *)

val empty : t
(** [empty] is an empty [Cache-Control] value. *)

val add : ?v:'a -> 'a Directive.t -> t -> t
(** [add ?v d t] adds cache-control directive [d] with value [v] to [t].

    If [Directive.is_bool d = true] then [v] is ignored.

    @raise Invalid_arg
      if [Directive.is_bool d = false] and [v = None] since a non bool directive
      requires a value. *)

val find_opt : 'a Directive.t -> t -> 'a option
(** [find_opt d t] is [Some v] if directive [d] exists in [t]. [v] is value as
    denoted by [d].

    It is [None] if [d] doesn't exist in [t]. *)

val find : 'a Directive.t -> t -> 'a
(** [find d t] is [v] if directive [d] exists in [t]. [v] is the value as
    denoted by [d].

    If [Directive.is_bool d = true] then [v = true] denotes the existence of
    directive [d] and [v = false] denotes the absence of [d] in [t].

    @raise Not_found
      if [d] is not found in [t] and [Directive.is_bool d = false]. *)

(** {1:codec Codec} *)

val decode : string -> t
(** [decode s] decodes [s] into [t]. *)

val encode : t -> string
(** [encode t] is the string representation of [t]. *)
