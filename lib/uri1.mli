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

type query = private string
(** [query] is the URI encoded query component of a HTTP request target. The
    reserved characters in query name/value are percent encoded.

    See {{!https://datatracker.ietf.org/doc/html/rfc3986#section-3.4} Query}. *)

val make_query : (string * string) list -> query
(** [make_query name_values] is a query [q]. Each [(name,value)] pair in
    [name_values] is percent encoded and concatenated with '&' character. *)

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

type absolute_form = scheme * authority * path * query option
(** [absolute_form] is the absolute uri form.

    See {{!https://www.rfc-editor.org/rfc/rfc9112#section-3.2.2} absolute-form} *)

val pp_absolute_form : Format.formatter -> absolute_form -> unit
(** [pp_absoltue_form fmt absolute_form] pretty prints [absolute_form] onto
    [fmt]. *)

val absolute_form : absolute_form Buf_read.parser
(** [absolute_form] parses request target in an [absolute-form].

    Example request target in absolute-form,

    {[
      http://www.example.org/pub/WWW/TheProject.html
    ]}

    See {{!https://www.rfc-editor.org/rfc/rfc9112#section-3.2.2} absolute-form} *)

type 'a t
(** [t] is the HTTP request target value. *)

val of_string : string -> [ `raw ] t
(** [of_string url] is [t] iff [url] contains a valid url value in string
    representation. [url] can be in one of the forms as listed below:

    + origin-form - only holds URI path and query information. Starts with [/]
      e.g. [/home/products]. See
      {{!https://www.rfc-editor.org/rfc/rfc9112#name-origin-form} origin-form}.

    + absolute-form - holds scheme,authority, path and query, eg.
      [http://www.example.org/pub/WWW/TheProject.html]. See
      {{!https://www.rfc-editor.org/rfc/rfc9112#name-authority-form}
      authority-form}.

    + authority-form - holds [host] and [port] information, e.g.
      [www.example.com:8080]. See
      {{!https://www.rfc-editor.org/rfc/rfc9112#name-authority-form}
      authority-form}.

    + asterisk-form - request-target with value [*]. See
      {{!https://www.rfc-editor.org/rfc/rfc9112#name-asterisk-form}
      asterisk-form}.

    {{!https://www.rfc-editor.org/rfc/rfc9112#name-request-target} RFC 9112 -
    request target}.

    @raise Invalid_argument if [url] contains invalid url value. *)

val origin_form : 'a t -> [ `origin ] t
(** [origin_form t] is request target of form [`origin t] iff [t] is in origin
    form.

    @raise Invalid_argument if [t] is not in origin-form. *)

(** {2 Authority Form} *)

val authority_form : 'a t -> [ `authority ] t
(** [authority_form t] is request target of form [`authority t] iff [t] is in
    authority form.

    @raise Invalid_argument if [t] is not in authority-form. *)

val authority' : [ `authority ] t -> host * port
(** [authority t] is [host, port]. *)

val asterisk_form : 'a t -> [ `asterisk ] t
(** [asterisk_form t] is request target of form [`asterisk t] iff [t] is in
    asterisk form.

    @raise Invalid_argument if [t] is not in asterisk.form. *)

val pp : Format.formatter -> 'a t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
