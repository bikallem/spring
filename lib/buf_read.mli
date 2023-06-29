include module type of Eio.Buf_read

val token : string parser

val crlf : unit parser

val not_cr : char -> bool

val ows : unit parser

val space : unit parser

val quoted_string : string parser

val parameters : (string * string) list parser

val cookie_pair : (string * string) parser

val list1 : 'a parser -> 'a list parser
