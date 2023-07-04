(** HTTP [Set-Cooki]e header functionality as specified in
    {{!https://datatracker.ietf.org/doc/html/rfc6265} RFC 6265}.

    {b Note} Additional functionality supported in addition to the above RFC:

    + Same-Site cookie attribute value. See
      {{!https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-cookie-same-site-00#section-1}
      SameSite Attribute}
    + Cookie Name Prefix encoding/decoding. See
      {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes}
      Cookie Name Prefixes} *)

(** {1:attribute Set-Cookie Attributes} *)

module Attribute : sig
  type 'a t
  (** ['a t] represents [Set-Cookie] attribute name and codecs to decode/encode
      attribute value. [a'] represents the OCaml type encoded by [t]. *)

  val name : 'a t -> string
  (** [name t] is the name of the attribute [t]. *)

  val is_bool : 'a t -> bool
  (** [is_bool t] is [true] if attribute [t] encapsulates a bool value. *)
end

val expires : Date.t Attribute.t
(** [expires] is the [Expires] [Set-Cookie] attribute.

    See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.1}
    Expires} *)

val max_age : int Attribute.t
(** [max_age] is the [Max-Age] [Set-Cookie] attribute.

    See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.2}
    Max-Age}.*)

val path : string Attribute.t
(** [path] is the [Path] attribute.

    See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.4} Path}. *)

val domain : [ `raw ] Domain_name.t Attribute.t
(** [domain] is the [Domain] [Set-Cookie] attribute.

    See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.3}
    Domain}. *)

val secure : bool Attribute.t
(** [secure] is the [Secure] [Set-Cookie] attribute.

    See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.5}
    Secure} *)

val http_only : bool Attribute.t
(** [http_only] is the [HttpOnly] [Set-Cookie] attribute.

    {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.6} HttpOnly}. *)

(** {2 SameSite}

    Controls the scope of cookies attached to requests in a user-agent.

    See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-the-samesite-attribute}
    Same-Site} *)

type same_site = private string
(** [same_site] is the [SameSite] attribute value. *)

val strict : same_site
(** [strict] denotes to the user-agent that the cookie should only be attached
    to requests origininating from the same site. See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#strict-lax}
    Strict/Lax Algorithm}. *)

val lax : same_site
(** [lax] denotes to the user-agent that the cookie should be attached to both
    same-site and cross-site top-level navigation.

    See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#strict-lax}
    Strict/Lax Algorithm}. *)

val same_site : same_site Attribute.t
(** [same_site] is the [SameSite] [Set-Cookie] attribute. *)

(** {1 Set-Cookie} *)

type t
(** [t] represents a HTTP Set-Cookie header value. *)

val make : ?extension:string -> name:string -> string -> t
(** [make ~name v] creates [Set-Cookie] value [t] with name [name] and value
    [v].

    @param extension
      is the extension attribute value for [t]. Default is [None].
    @raise Invalid_arg if [name] is an empty string. *)

val name : t -> string
(** [name t] is the name of [Set-Cookie] value [t]. *)

val value : t -> string
(** [value t] is the value of [Set-Cookie] value [t]. *)

val extension : t -> string option
(** [extension t] is [Some v] if an extension attribute value is defined for
    [t]. *)

val expire : t -> t
(** [expire t] configures [t] to be expired/removed by user-agents. This is done
    by setting [Max-Age] attribute to [-1] and removing all other attributes in
    [t]. *)

val is_expired : #Eio.Time.clock -> t -> bool
(** [is_expired clock t] is [true] if [find max_age t <= 0] or if
    [find expires t < Date.now clock]. *)

val add : ?v:'a -> 'a Attribute.t -> t -> t
(** [add v attr t] adds attribute defined by [attr] and value [v] to [t].

    If attribute [attr] already exists in [t], then the old value is replaced
    with [v].

    @param v
      is ignored if [Attribute.is_bool attr = true]. Otherwise the value is
      required.
    @raise Invalid_arg
      if [Attribute.is_bool d = false] and [v = None] since a non bool attribute
      requires a value. *)

val find : 'a Attribute.t -> t -> 'a
(** [find attr t] is [v] if attribute [attr] exists in [t]. [v] is the value as
    denoted by [attr].

    If [Attribute.is_bool attr = true] then [v = true] and [v = false] denotes
    the existence and absence respectively of attribute [attr] in [t].

    @raise Not_found
      if attribute [attr] is not found in [t] and
      [Attribute.is_bool attr = false].
    @raise Failure
      if [Attribute.is_bool attr = false] and decoding [v] results in error. *)

val find_opt : 'a Attribute.t -> t -> 'a option
(** [find_opt attr t] is [Some v] if attribute [attr] exists in [t]. Otherwise
    it is [None]. *)

val remove : 'a Attribute.t -> t -> t
(** [remove attr t] is [t] with attribute [attr] removed. *)

val compare : t -> t -> int
(** [compare t0 t1] compares [t0] and [t1]. The comparison is done the following
    way.

    + Names and values of [t0] and [t1] are compared in a case-sensitive manner.
    + The attribute names are compared case-insensitively
    + The attribute values are compared according to the value the attribute
      encodes.

    [compare t0 t1 = 0] is same as [equal t0 t1 = true]. *)

val equal : t -> t -> bool
(** [equal t0 t1] is [compare t0 t1 = 0]. *)

(** {2 Codecs} *)

val decode : ?process_name_prefix:bool -> string -> t
(** [decode s] decodes string [s] into [t].

    The grammar followed is specified at
    {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.1} Set-Cookie
    syntax}

    {b Note} if the [Set-Cookie] value is double quoted, then double quotes are
    part of the value and are not stripped. See
    {{!https://github.com/httpwg/http-extensions/issues/295} Double quoted
    value}.

    @param process_name_prefix
      if [true] and [name t] starts with either [__Secure-] or [__Host-], then
      the prefix will be removed from [name] property of [t]. Default is [true].
      See
      {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes}
      Cookie Name Prefixes}. *)

val encode : ?prefix_name:bool -> t -> string
(** [encode t] encodes [t] to [s].

    @param prefix_name
      if [true] then [name] will be prefixed with either [__Secure-] or
      [__Host-] as required. Default is [true]. See
      {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes}
      Cookie Name Prefixes}. *)

(** {2 Pretty Printing} *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
