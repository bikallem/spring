include module type of Eio.Buf_read

val token : string parser

val crlf : unit parser

val not_cr : char -> bool

val ows : unit parser

val space : unit parser

val quoted_pair : char parser

val quoted_text : char parser

val quoted_string : string parser

val parameters : (string * string) list parser

val cookie_pair : (string * string) parser

val list1 : 'a parser -> 'a list parser
(** [list1 p] is a parser that parses at least one element as defined by [p].

    Implement HTTP RFC list element syntax - #element. See
    https://www.rfc-editor.org/rfc/rfc9110#name-lists-rule-abnf-extension *)

val delta_seconds : int parser
(** [delta_seconds] parses [s]. [s] is a non-negative integer representing time
    span in seconds.

    See {{!https://www.rfc-editor.org/rfc/rfc9111#delta-seconds} HTTP
    delta-seconds}. *)
