(** HTTP URI (Uniform Resource Identifier).

    URI is used to implement HTTP request target specification.

    {b References}

    - RFC 9112
      {e {{!https://www.rfc-editor.org/rfc/rfc9112#name-request-target} HTTP
         Request Target}}.

    - RFC 9110
      {e {{!https://www.rfc-editor.org/rfc/rfc9110#name-uri-references} HTTP
         URI}}.

    - RFC 3986
      {e {{!https://datatracker.ietf.org/doc/html/rfc3986#appendix-A} URI
         Generic Syntax}} *)

type absolute_path = string list
(** [absolute_path] is the path component of a HTTP request target. It starts
    with [/] and ends with possibly [?] character.

    Example of a path,

    {[
      /pub/WWW/TheProject.html
    ]}

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.3} Path}. *)

type query = string
(** [query] is the query component of a HTTP request target. It starts with [?]
    character.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.4} Query}. *)

val origin_form : (absolute_path * query option) Buf_read.parser
(** [origin_form] is [absolute_path, Some query].

    [origin-form    = absolute-path \[ "?" query \]]

    See {{!https://www.rfc-editor.org/rfc/rfc9112#name-origin-form} Origin
    Form}. *)

type host =
  [ `IPv6 of Ipaddr.t
  | `IPv4 of Ipaddr.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]
(** [host] identifies a server. It is either an IPv6, IPv4 or a domain name.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2} Host}. *)

type port = int
(** [port] denotes the TCP port number.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.3} Port}. *)

type authority = host * port option
(** [authority] identifies an origin server of a HTTP request, i.e. the server
    that consumes a HTTP request and produces a response.

    {b Note} HTTP Uri has deprecated the user-info in an authority. See
    {{!https://www.rfc-editor.org/rfc/rfc9110#name-deprecation-of-userinfo-in-}
    user-info deprecation}.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.2}
    Authority}. *)

val pp_authority : Format.formatter -> authority -> unit
(** [pp_authority fmt auth] pretty prints [auth] onto [fmt]. *)

val authority : authority Buf_read.parser
(** [authority buf_read] parses [authority] information from [buf_read]. *)

type scheme =
  [ `Http
  | `Https
  ]
(** [scheme] is the request target schemes supported by HTTP.

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-http-related-uri-schemes}
    HTTP Schemes} *)

val absolute_form :
  (scheme * authority * absolute_path * query option) Buf_read.parser
(** [absolute_form] parses request target in an [absolute-form].

    Example request target in absolute-form,

    {[
      http://www.example.org/pub/WWW/TheProject.html
    ]}

    See {{!https://www.rfc-editor.org/rfc/rfc9112#section-3.2.2} absolute-form} *)

val authority_form : (host * port) Buf_read.parser
(** [authority_form] is the request target for [CONNECT] requests. It consists
    of only the host and port number.

    See {{!https://www.rfc-editor.org/rfc/rfc9112#name-authority-form}
    authority-form}. *)
