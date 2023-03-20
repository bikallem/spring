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
| "fun" ws* ((_)+ as params) "->" { Func params }

and element = parse
| ws* { element lexbuf }
| '<' { Tag_open }
| "</" { Tag_open_slash }
| '{' { Code_open }
| "<!--" ((_)* as comment) "-->" { Html_comment comment }
| "<![CDATA[" ((_)* as cdata) "]]>" { Cdata cdata }
| "<![" ((_)* as comment) "]>" { Html_conditional_comment comment }
| "<!" { dtd (Buffer.create 10) lexbuf }
| html_text { Html_text text }
| eof { Eof }
| _ as c { err c lexbuf }

and dtd buf = parse
| '>' { Dtd (Buffer.contents buf) }
| _ as c { Buffer.add_char buf c; dtd buf lexbuf } 

and tag = parse
| ws* { tag lexbuf }
| '>' { Tag_close }
| "/>" { Tag_slash_close }
| '=' { Tag_equals }
| '{' { code_attr (Buffer.create 10) lexbuf }
| tag_name as name { Tag_name name }
| eof { Eof }
| _ as c { err c lexbuf }

and code_attr buf = parse
| '}'      { Code_attr (Buffer.contents buf) }
| '\\' '}' { Buffer.add_char buf '}'; code_attr buf lexbuf }
| _ as c   { Buffer.add_char buf c; code_attr buf lexbuf }
| eof      { Eof }

and attribute_val = parse
| ws* { attribute_val lexbuf }
| '\'' ([^ '<' '\'']* as v) '\'' { Single_quoted_attr_val v }
| '"' ([^ '<' '"']* as v) '"'    { Double_quoted_attr_val v }
| '{' ([^ '}']* as v) '}'        { Code_attr_val v }
| ([^ ' ''\t' '\n' '\r' '\x09' '\'' '"' '=' '<' '>' '`']+ as v) { Unquoted_attr_val v }
| eof { Eof }
| _ as c { err c lexbuf }

and code = parse
| ws* { code lexbuf }
| '{' { code_block (Buffer.create 20) lexbuf }
| '}' { Code_close }
| '<' { Tag_open }
| "</" { Tag_open_slash }
| "<text>" ((_)* as text) "</text>" { Html_text text } 
| eof { Eof }

and code_block buf = parse
| '}'     { Code_block (Buffer.contents buf) }
| "\\}"   { Buffer.add_char buf '}'; code_block buf lexbuf }
| _ as c  { Buffer.add_char buf c; code_block buf lexbuf }
| eof     { Eof }
