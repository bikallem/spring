module Node = Node
module Doc = Doc

exception Syntax_error of int * int

val parse_element : string -> Doc.doc
(** [parse_element content] parses ohtml content in [content]. *)

val parse_doc_string : string -> Doc.doc
(** [parse_doc_string content] parses ohtml content in [content]. *)

val parse_doc : string -> Doc.doc
(** [parse_doc filepath] parses .ohtml file at [filepath]. *)

val gen_ocaml : write_ln:(string -> unit) -> Doc.doc -> unit
