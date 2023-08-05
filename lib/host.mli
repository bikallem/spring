(** HTTP [Host] header.

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-host-and-authority}
    Host}. *)

type t
(** [t] is the HTTP Host header value. It encapsulates host details of a HTTP
    request. *)

val make : ?port:int -> Uri1.host -> t
(** [make host] is [t].

    @param port is the TCP/IP port. Default is [None] *)

val host : t -> Uri1.host
(** [v t] is [host] component of [t]. *)

val port : t -> Uri1.port option
(** [port t] is the [port] component of [t]. *)

val decode : string -> t
(** [decode s] is [t] if the authority information in [s] can be successfully
    parsed into [t]. *)

val encode : t -> string
(** [encode t] encodes [t] into a string representation. *)

val equal : t -> t -> bool
(** [equal t0 t1] is [treu] iff [t0] is equal to [t1]. *)

val compare : t -> t -> int
(** [compare t0 t1] orders [t0] and [t1] such that [compare t0 t1 = 0] is
    equivalent to [equal t0 t1 = true]. The ordering follows the host ordering
    as follows: [IPv6]. [IPv4] and [Domain_name] *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
