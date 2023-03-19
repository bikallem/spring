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
  | Code of code list
  | Html_text of string
  | Html_comment of string
  | Html_conditional_comment of string
  | Cdata of string

and code =
  | Code_block of string
  | Code_text of string
  | Code_element of
      { tag_name : string; attributes : attribute list; children : code list }

type dtd = Dtd of string
type doc = { fun_args : string option; dtd : string option; root : element }

let element :
    ?attributes:attribute list -> ?children:element list -> string -> element =
 fun ?(attributes = []) ?(children = []) tag_name ->
  Element { tag_name; attributes; children }
