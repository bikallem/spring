{
  open Parser1
  exception Error of string

  let err c lexbuf = 
    let offset = Lexing.lexeme_start lexbuf in
    let err = Printf.sprintf "At offset %d: unexpected character '%c'." offset c in
    failwith err
}

let alpha = ['a'-'z'] | ['A'-'Z']
let num = ['0'-'9']
let tag_name = (alpha | '_') (alpha | num | '_' | '\'' | '.')*
let ws = [' ' '\t' '\n' '\r' '\x09']
let html_text = ws* ([^ '<' '{']+ as text)

rule func = parse
| ws* { func lexbuf }
| "fun" ws* ((_)+ as params) "->" { FUNC params }

and element = parse
| ws* { element lexbuf }
| '<' { TAG_OPEN }
| "</" { TAG_OPEN_SLASH }
| '{' { CODE_OPEN }
| "<!--" ((_)* as comment) "-->" { HTML_COMMENT comment }
| "<![CDATA[" ((_)* as cdata) "]]>" { CDATA cdata }
| "<![" ((_)* as comment) "]>" { HTML_CONDITIONAL_COMMENT comment }
| "<!" { dtd (Buffer.create 10) lexbuf }
| html_text { HTML_TEXT text }
| eof { EOF }
| _ as c { err c lexbuf }

and dtd buf = parse
| '>' { DTD (Buffer.contents buf) }
| _ as c { Buffer.add_char buf c; dtd buf lexbuf } 

and tag = parse
| ws* { tag lexbuf }
| '>' { TAG_CLOSE }
| "/>" { TAG_SLASH_CLOSE }
| '=' { TAG_EQUALS }
| '{' { code_attr (Buffer.create 10) lexbuf }
| tag_name as name { TAG_NAME name }
| eof { EOF }
| _ as c { err c lexbuf }

and code_attr buf = parse
| '}'      { CODE_ATTR (Buffer.contents buf) }
| '\\' '}' { Buffer.add_char buf '}'; code_attr buf lexbuf }
| _ as c   { Buffer.add_char buf c; code_attr buf lexbuf }
| eof      { EOF }

and attribute_val = parse
| ws* { attribute_val lexbuf }
| '\'' ([^ '<' '\'']* as v) '\'' { ATTR_VAL v }
| '"' ([^ '<' '"']* as v) '"'    { ATTR_VAL v }
| '{' ([^ '}']* as v) '}'        { ATTR_VAL_CODE v }
| ([^ ' ''\t' '\n' '\r' '\x09' '\'' '"' '=' '<' '>' '`']+ as v) { ATTR_VAL v }
| eof { EOF }
| _ as c { err c lexbuf }

and code = parse
| ws* { code lexbuf }
| '{' { code_block (Buffer.create 20) lexbuf }
| '}' { CODE_CLOSE }
| '<' { TAG_OPEN }
| "</" { TAG_OPEN_SLASH }
| "<text>" ((_)* as text) "</text>" { HTML_TEXT text } 
| eof { EOF }

and code_block buf = parse
| '}'     { CODE_BLOCK (Buffer.contents buf) }
| "\\}"   { Buffer.add_char buf '}'; code_block buf lexbuf }
| _ as c  { Buffer.add_char buf c; code_block buf lexbuf }
| eof     { EOF }
