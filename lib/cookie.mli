(** HTTP Cookie header functionality as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2

    Additionally, cookie name prefixes - [__Host-] and [__Secure-] are
    supported. See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes-2}
    Cookie Name Prefixes}.

    The cookie-name-prefix decoding is case-sensitive. *)

type t
(** [t] represents a collection of HTTP cookies. [t] holds one or more values
    indexed via a case-sensitive cookie name. *)

val decode : string -> t
(** [decode s] decodes [s] into [t].

    {b Note} Cookie name prefix is decoded case-sensitively. *)

val encode : t -> string
(** [encode t] encodes [t] into a string representation. *)

val empty : t
(** [empty] is an HTTP Cookie header with zero cookie pair (name, value) *)

val name_prefix : string -> t -> Cookie_name_prefix.t option
(** [name_prefix name t] is [Some prefix] if cookie with name [name] exists in
    [t] and the cookie has a name prefix. It is [None] otherwise.

    See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes-2}
    Cookie Name Prefixes}. *)

val find_opt : string -> t -> string option
(** [find_opt cookie_name t] is [Some v] if [cookie_name] exists in [t]. It is
    [None] otherwise. *)

val add : ?name_prefix:Cookie_name_prefix.t -> name:string -> value:string -> t -> t
(** [add ~name ~value t] adds a cookie [name] and [value] pair to [t] *)

val remove : name:string -> t -> t
(** [remove ~name t] is [t] with cookie [name] removed from [t]. *)
