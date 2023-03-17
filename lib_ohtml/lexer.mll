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
let ws = [ ' ' '\t' '\n' '\r' '\x09']

rule element = parse
| ws { element lexbuf }
| '<' { TAG_OPEN }
| "</" { TAG_OPEN_SLASH } 
| '{' { code_block (Buffer.create 10) lexbuf }
| "<!--" ((_)* as comment) "-->" { HTML_COMMENT comment }
| "<![" ((_)* as comment) "]>" { HTML_CONDITIONAL_COMMENT comment }
| "<![CDATA[" ((_)* as cdata) "]]>" { CDATA cdata }
| _ as c { err c lexbuf }

and tag = parse
| ws { tag lexbuf }
| '>' { TAG_CLOSE }
| "/>" { TAG_SLASH_CLOSE }
| '=' { TAG_EQUALS }
| '{' { code_block (Buffer.create 10) lexbuf }
| tag_name as name { TAG_NAME name }
| eof { EOF }
| _ as c { err c lexbuf }

and code_block buf = parse
| '}'      { CODE_BLOCK (Buffer.contents buf) }
| '\\' '}' { Buffer.add_char buf '}'; code_block buf lexbuf }
| _ as c   { Buffer.add_char buf c; code_block buf lexbuf }
| eof      { EOF }

and attribute_val = parse
| ws* '\'' ([^ '<' '\'']* as v) '\'' { ATTR_VAL v }
| ws* '"' ([^ '<' '"']* as v) '"'    { ATTR_VAL v }
| ws* '{' ([^ '}']* as v) '}'        { ATTR_VAL_CODE v }
| ws* ([^ ' ''\t' '\n' '\r' '\x09' '\'' '"' '=' '<' '>' '`']+ as v) { ATTR_VAL v }
| eof { EOF }
| _ as c { err c lexbuf }
