module Node = Node
module Doc = Doc

exception Syntax_error of int * int

val parse_element : string -> Doc.doc
val parse_doc_string : string -> Doc.doc
val gen_ocaml : fun_name:string -> write_ln:(string -> unit) -> Doc.doc -> unit
