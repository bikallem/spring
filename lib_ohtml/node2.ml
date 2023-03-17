type attribute =
  | Code_attribute of string
  | Bool_attribute of string
  | Name_val_attribute of (string * string)
  | Name_code_val_attribute of (string * string)

type element =
  | Element of
      { tag_name : string
      ; attributes : attribute list
      ; children : element list
      }
  | Code_block of string
  | Html_text of string
  | Html_comment of string
  | Html_conditional_comment of string
  | Cdata of string

let element :
    ?attributes:attribute list -> ?children:element list -> string -> element =
 fun ?(attributes = []) ?(children = []) tag_name ->
  Element { tag_name; attributes; children }
