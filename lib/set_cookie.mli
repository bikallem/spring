(** [Set_cookie] implements HTTP [Set-Cooki]e header functionality as specified
    in https://datatracker.ietf.org/doc/html/rfc6265

    Addtionally, the module also supports Same-Site cookie attribute value as
    specified in
    https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-cookie-same-site-00#section-1 *)

type t
(** [t] represents a HTTP Set-Cookie header value. *)

(** {1 Create} *)

type name_value = string * string

type same_site = private string

(** {1 Same Site} *)

val strict : same_site

val lax : same_site

(** {1 Create} *)

val make :
     ?expires:Date.t
  -> ?max_age:int
  -> ?domain:[ `raw ] Domain_name.t
  -> ?path:string
  -> ?secure:bool
  -> ?http_only:bool
  -> ?extensions:string list
  -> ?same_site:same_site
  -> name_value
  -> t
(** [make (nm,v)] is [t] with set_cookie name [nm] and value [v].

    See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie for
    parameter details.

    @param http_only Default value is [true].
    @param secure Default value is [true]. *)

val decode : string -> t

val encode : t -> string

(** {1 Cookie Attributes} *)

val name : t -> string

val value : t -> string

val expires : t -> Date.t option

val max_age : t -> int option

val domain : t -> [ `raw ] Domain_name.t option

val path : t -> string option

val secure : t -> bool

val http_only : t -> bool

val extensions : t -> string list

val same_site : t -> same_site option

(** {1 Expire a Cookie} *)

val expire : t -> t
(** [expire t] configures [t] to be expired/removed by user-agents. *)

(** {1 Pretty Printing} *)

val pp : Format.formatter -> t -> unit

module New : sig
  (** {1:attribute Set-Cookie Attributes} *)

  module Attribute : sig
    type 'a t
    (** ['a t] represents [Set-Cookie] attribute name and codecs to
        decode/encode attribute value. [a'] represents the OCaml type encoded by
        [t]. *)

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

      See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.4}
      Path}. *)

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

      {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.2.6}
      HttpOnly}. *)

  (** {1 Set-Cookie} *)

  type t
  (** [t] represents a HTTP Set-Cookie header value. *)

  val make : ?extension:string -> name:string -> string -> t
  (** [make ~name v] creates [Set-Cookie] value [t] with name [name] and value
      [v].

      @param extension
        is the extension attribute value for [t]. Default is [None]. *)

  val name : t -> string
  (** [name t] is the name of [Set-Cookie] value [t]. *)

  val value : t -> string
  (** [value t] is the value of [Set-Cookie] value [t]. *)

  val extension : t -> string option
  (** [extension t] is [Some v] if an extension attribute value is defined for
      [t]. *)

  val add : ?v:'a -> 'a Attribute.t -> t -> t
  (** [add v attr t] adds attribute defined by [attr] and value [v] to [t].

      @param v
        is ignored if [Attribute.is_bool attr = true]. Otherwise the value is
        required.
      @raise Invalid_arg
        if [Attribute.is_bool d = false] and [v = None] since a non bool
        attribute requires a value. *)

  val find : 'a Attribute.t -> t -> 'a
  (** [find attr t] is [v] if attribute [attr] exists in [t]. [v] is the value
      as denoted by [attr].

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

  (** {2 Codecs} *)

  val decode : string -> t
  (** [decode s] decodes string [s] into [t].

      The grammar followed is specified at
      {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.1} Set-Cookie
      syntax} *)

  val encode : t -> string
  (** [encode t] encodes [t] to [s]. *)
end
