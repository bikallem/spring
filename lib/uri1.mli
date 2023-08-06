(** HTTP URI (Uniform Resource Identifier).

    URI is used to implement HTTP request target specification.

    Some notable differences (of HTTP URI) with that of Generic URI syntax:

    + Absolute paths starting with '//' are not allowed.
    + user-name info in authority is deprecated.
    + The only schemes allowed are [http] and https.
    + uri fragments (e.g. [#section1]) is not allowed.

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

type path = private string list
(** [path] is the path component of a HTTP request target. It starts with [/]
    and ends with possibly [?] character.

    Example of a path,

    {[
      /pub/WWW/TheProject.html
    ]}

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.3} Path}. *)

val make_path : string list -> path
(** [make_path l] is absolute path [p]. [l] is the list of path components which
    are percent encoded in [p]. *)

val path_to_string : path -> string
(** [path_to_string p] is path [p] formatted to HTTP path format. *)

type query = private string
(** [query] is the URI encoded query component of a HTTP request target. The
    reserved characters in query name/value are percent encoded.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.4} Query}. *)

val make_query : (string * string) list -> query
(** [make_query name_values] is a query [q]. Each [(name,value)] pair in
    [name_values] is percent encoded and concatenated with '&' character. *)

type origin_uri = private path * query option
(** [origin_uri] holds URI path and query information. Starts with [/] e.g.
    [/home/products]. See
    {{!https://www.rfc-editor.org/rfc/rfc9112#name-origin-form} origin-form}. *)

val origin_uri : string -> origin_uri
(** [origin_uri s] decodes [s] into [origin_uri].

    @raise Invalid_argument if [s] doesn't contain valid origin_uri data. *)

val pp_origin_uri : Format.formatter -> origin_uri -> unit
(** [pp_origin_uri fmt origin_uri] pretty prints [origin_uri] onto [fmt]. *)

type host =
  [ `IPv6 of Ipaddr.V6.t
  | `IPv4 of Ipaddr.V4.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]
(** [host] identifies a server. It is either an IPv6, IPv4 or a domain name.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.2} Host}. *)

type port = int
(** [port] denotes the TCP port number.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.3} Port}. *)

type authority = host * port option
(** [authority] is the host and an optional port information. *)

val authority : string -> authority
(** [authority s] decodes [s] into authority. *)

val pp_authority : Format.formatter -> authority -> unit
(** [pp_authority fmt auth] pretty prints [auth] onto [fmt]. *)

type scheme =
  [ `Http
  | `Https
  ]
(** [scheme] is the request target schemes supported by HTTP.

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-http-related-uri-schemes}
    HTTP Schemes} *)

type absolute_uri = private scheme * host * port option * path * query option
(** [absolute_uri] is a uri in an absolute form as specified in
    {{!https://www.rfc-editor.org/rfc/rfc9112#name-authority-form}
    authority-form}. It allows to specify [scheme], [authority], [path] and
    [query] parts of a uri. eg.
    [http://www.example.org/pub/WWW/TheProject.html]. *)

val absolute_uri : string -> absolute_uri
(** [absolute_uri s] decodes [s] into [absolute_uri].

    @raise Invalid_argument if [s] contains invalid absolute uri value. *)

val path_and_query : absolute_uri -> string
(** [path_and_query uri] formats path and query components of absolute-uri [uri]
    into a string. *)

val host_and_port : absolute_uri -> host * port option
(** [host_and_port uri] is the host and port component of [uri]. *)

val pp_absolute_uri : Format.formatter -> absolute_uri -> unit
(** [pp_absolute_uri fmt uri] pretty prints [uri] onto [fmt]. *)

type authority_uri = private host * port
(** [authority_uri] is an uri in an authority form as specified in
    {{!https://www.rfc-editor.org/rfc/rfc9112#name-authority-form}
    authority-form}.

    e.g. [www.example.com:8080]

    It is mostly used with [CONNECT] and [OPTIONS] HTTP methods. *)

val authority_uri : string -> authority_uri
(** [authority_uri s] decodes [s] into [authority_uri].

    @raise Invalid_argument if [s] contains invalid authority-uri data. *)

val pp_authority_uri : Format.formatter -> authority_uri -> unit
(** [pp_authority_uri fmt uri] pretty prints [uri] onto [fmt]. *)

type asterisk_uri
(** [asterisk_uri] is the uri in asterisk-form as specified in
    {{!https://www.rfc-editor.org/rfc/rfc9112#name-asterisk-form}
    asterisk-form}.

    It is used with HTTP [OPTIONS] method. *)

val asterisk_uri : string -> asterisk_uri
(** [asterisk_uri s] decodes [s] into uri of [asterisk-form]. *)

val pp_asterisk_uri : Format.formatter -> asterisk_uri -> unit
(** [pp_asterisk_uri fmt uri] pretty prints [uri] onto [fmt]. *)