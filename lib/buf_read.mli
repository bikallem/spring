include module type of Eio.Buf_read

val take_while1 : ?on_error:(unit -> string) -> (char -> bool) -> string parser
(** [take_while1 p] is like {!val:Eio.Buf_read.take_while1} except calls
    [on_error] when it consumes less than one character of input.

    @param on_error By default it fails with "take_while1". *)

val token : string parser

val crlf : unit parser

val not_cr : char -> bool

val ows : unit parser

val space : unit parser

val quoted_pair : char parser

val quoted_text : char parser

val quoted_string : string parser

val parameters : (string * string) list parser

val cookie_pair :
  ?name_prefix_case_sensitive:bool -> ((string * string option) * string) parser
(** [cookie_pair t] parses [t] into a tuple of
    [((cookie-name, cookie-name-prefix), value)].

    See {{!https://datatracker.ietf.org/doc/html/rfc6265#section-4.1.1}
    Cookie/Set-Cookie Syntax}.

    In addition to the above RFC, a draft standard RFC concerning the Cookie
    name prefix is implemented. See
    {{!https://httpwg.org/http-extensions/draft-ietf-httpbis-rfc6265bis.html#name-cookie-name-prefixes}
    Cookie Name Prefix}.

    @param name_prefix_case_sensitive
      if [true] then the cookie name prefix is matched in a case-sensitive
      manner. It is recommended that this be set to [true] when parsing Cookie
      name on the server and [false] when parsing cookie name on the
      client/user-agent. Default is [true]. *)

val list1 : 'a parser -> 'a list parser
(** [list1 p] is a parser that parses at least one element as defined by [p].

    Implement HTTP RFC list element syntax - #element. See
    https://www.rfc-editor.org/rfc/rfc9110#name-lists-rule-abnf-extension *)

val delta_seconds : int parser
(** [delta_seconds] parses [s]. [s] is a non-negative integer representing time
    span in seconds.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#delta-seconds} HTTP
    delta-seconds}. *)
