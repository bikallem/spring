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

type segment = string

val segment : segment Buf_read.parser
(** [segment] is a string [s]. [s] satisfies the following grammar.

    [segment = *pchar]
    [pchar = unreserved / pct-encoded / sub-delims / ":" / "@"] *)

val absolute_path : segment list Buf_read.parser
(** [absolute_path] is a string [s] *)
