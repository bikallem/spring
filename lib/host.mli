(** HTTP [Host] header.

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-host-and-authority}
    Host}. *)

type host =
  [ `IPv6 of Ipaddr.V6.t
  | `IPv4 of Ipaddr.V4.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]
(** [host] identifies a server. It is either an IPv6, IPv4 or a domain name.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2} Host}. *)

type port = int
(** [port] is the TCP/IP port number. *)

type t = private host * port option
(** [t] is the HTTP Host header value. It encapsulates host details of a HTTP
    request. *)

val decode : string -> t
(** [decode s] is [t] if the authority information in [s] can be successfully
    parsed into [t]. *)

val encode : t -> string
(** [encode t] encodes [t] into a string representation. *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
