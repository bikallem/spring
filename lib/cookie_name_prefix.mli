(** [Cookie_name_prefix] is the cookie name prefix - [__Host-] or [__Secure-].

    See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes}
    Cookie Name Prefix}. *)

type t
(** [t] is the Cookie name prefix value. It can be either [__Host-] or
    [__Secure-] prefix. *)

val host : t
(** [host] is the [__Host-] cookie name prefix.*)

val secure : t
(** [secure] is the [__Secure-] cookie name prefix.*)

val contains_prefix : ?case_sensitive:bool -> string -> t -> bool
(** [contains_prefix name t] is [true] if cookie name [name] starts with the
    prefix value [t].

    @param case_sensitive
      if [true] then the prefix matching is case-sensitive. Default is [true]. *)

val cut_prefix : ?case_sensitive:bool -> string -> string * t option
(** [cut_prefix ?case_sensitive name] is [name', Some t] if [name] starts with
    one of {!val:host} or {!val:secure} prefix. [name'] is the cookie name after
    removing the matched cookie name prefix from [name]. [Some t] is the matched
    cookie name prefix.

    If [name] doesn't prefix any of the two cookie name prefixes, then it is
    [name, None] .i.e. [name] is unchanged. *)

val to_string : t -> string
(** [to_string t] is the string representation of [t]. *)

val compare : t -> t -> int
(** [compare t0 t1] orders [t0] and [t1]. The comparison is case-sensitive. *)

val equal : t -> t -> bool
(** [equal t0 t1] is [true] iff [t0] and [t1] are equal. *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
