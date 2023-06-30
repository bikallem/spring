(** HTTP Cache-Control header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#name-cache-control *)

(** {1:directives Directives} *)

(** [Directive] controls various caching functionality in HTTP client or server,
    e.g. [Cache-Control : no-cache, max-age=5, private, custom="val1"].

    {! Extending Directives}

    Creating custom directives is supported via {!val:make} and
    {!val:make_bool_directive} functions. See
    {{!https://www.rfc-editor.org/rfc/rfc9111#name-extension-directives}
    Extension Directives}. *)
module Directive : sig
  type 'a t
  (** [t] is a cache-control directive value. *)

  type name = string
  (** [name] is a directive name. It is case-sensitive. *)

  val name : 'a t -> name
  (** [name t] is the name of the cache-directive [t]. *)

  (** {2:bool_directive Bool} *)

  type bool' = bool t
  (** [bool'] is a cache-directive that doesn't have a corresponding value
      associated with it, e.g. [no-cache, private, public] etc.

      [max-age] is not a bool directive as it has a value associated with it.
      value.

      See {!val:is_bool}. *)

  val make_bool_directive : name -> bool'
  (** [make_bool_directive name] makes a bool directive with name [name]. *)

  val is_bool : 'a t -> bool
  (** [is_bool t] is [true] if [t] is a bool directive.

      See {!type:bool_directive}. *)

  (** {2:name_value_directive Name Value} *)

  type 'a decode = string -> 'a
  (** [decode] is the decoder function for a name value directive. It decodes
      string value [s] into a required OCaml typed value.

      {b Quoted String Value}

      If the encoded directive value is a quoted string, i.e.
      [Cache-Control: custom="val1"], then the decoder will receive value [s]
      with the surrounding double quotes - ["val1"]. *)

  type 'a encode = 'a -> string
  (** [encode] is the encoder function for a name value directive. It encodes a
      typed Ocaml value into a string value. *)

  val make : name -> 'a decode -> 'a encode -> 'a t
  (** [make name decode encode] makes a name value directive with name [name]
      and decoder/encoder funtions [decode]/[encode] respectively. *)

  val decode : 'a t -> 'a decode option
  (** [decode t] is [Some f] if directive [t] is not a bool directive. [f] is
      the decoder function for [t].

      It is [None] if [t] is a bool directive. *)

  val encode : 'a t -> 'a encode option
  (** [encode t] is [Some f] if directive [t] is not a bool directive. [f] is
      the encoder function for [t].

      It is [None] if [t] is a bool directive. *)
end

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

    If [Directive.is_bool d = true] then [v = true] and [v = false] denotes the
    existence and absence respectively of directive [d] in [t].

    @raise Not_found
      if [d] is not found in [t] and [Directive.is_bool d = false]. *)

(** {1:codec Codec} *)

val decode : string -> t
(** [decode s] decodes [s] into [t]. *)

val encode : t -> string
(** [encode t] is the string representation of [t]. *)

(** {1 Standard Directives} *)

type delta_seconds = int
(** [delta_seconds] is time in seconds. *)

val max_age : delta_seconds Directive.t
(** [max_age] is [max-age] directive.

    {b Usage} HTTP request and response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-max-age} max-age} *)

val max_stale : delta_seconds Directive.t
(** [max_stale] is [max-stale] directive.

    {b Usage} HTTP request.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-max-stale} max-stale} *)

val min_fresh : delta_seconds Directive.t
(** [min_fresh] is [min-fresh] directive.

    {b Usage} HTTP request.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-min-fresh} min-fresh} *)

val no_cache : Directive.bool'
(** [no_cache] is [no-cache] directive.

    {b Usage} HTTP request and response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-no-cache} no-cache}. *)

val no_store : Directive.bool'
(** [no_store] is [no-store] directive.

    {b Usage} HTTP request and response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-no-store} no-store}. *)

val no_transform : Directive.bool'
(** [no_transform] is [no-transform] directive.

    {b Usage} HTTP request and response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-no-store} no-store}. *)

val only_if_cached : Directive.bool'
(** [only_if_cached] is [only-if-cached] directive.

    {b Usage} HTTP request.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-only-if-cached}
    only-if-cached}. *)

val must_revalidate : Directive.bool'
(** [must_revalidate] is [must-revalidate] directive.

    {b Usage} HTTP response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-must-revalidate}
    must-revalidate}. *)

val must_understand : Directive.bool'
(** [must_understand] is [must-understand] directive.

    {b Usage} HTTP response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-must-understand}
    must-understand}. *)

val private' : Directive.bool'
(** [private'] is [private] directive.

    {b Usage} HTTP response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-private} private}. *)

val proxy_revalidate : Directive.bool'
(** [proxy_revalidate] is [proxy-revalidate] directive.

    {b Usage} HTTP response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-proxy-revalidate}
    proxy-revalidate}. *)

val public : Directive.bool'
(** [public] is [public] directive.

    {b Usage} HTTP response.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#name-public} public}. *)
