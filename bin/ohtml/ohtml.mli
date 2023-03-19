module Node = Node
module Doc = Doc

exception Syntax_error of int * int

val parse_element: string -> Doc.doc
val parse_doc : string -> Doc.doc
