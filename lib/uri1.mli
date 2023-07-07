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

val absolute_path : ?buf:Buffer.t -> string list Buf_read.parser
(** [absolute_path] is a HTTP URI absolute path string [s]

    [absolute-path = 1*( "/" segment )]

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-uri-references} URI}. *)

val origin_form : (string list * string option) Buf_read.parser
(** [origin_form] is [absolute_path, Some query].

    [origin-form    = absolute-path \[ "?" query \]]

    See {{!https://www.rfc-editor.org/rfc/rfc9112#name-origin-form} Origin
    Form}. *)
