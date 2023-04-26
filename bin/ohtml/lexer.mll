{
  open Parser
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
let attr_name = [^ '\x7F'-'\x9F' '\x20' '"' '\'' '>' '/' '=' '{']+

rule func = parse
| ws* { func lexbuf }
| "open" { open_t (Buffer.create 10) lexbuf } 
| "fun" { func_params (Buffer.create 10) lexbuf }
| '<' { Func_empty (Tag_open) }
| "<!--" { Func_empty (html_comment (Buffer.create 20) lexbuf) }
| "<![CDATA[" { Func_empty (cdata (Buffer.create 10) lexbuf) }
| "<![" { Func_empty (html_conditional_comment (Buffer.create 10) lexbuf) }
| "<!" { Func_empty (dtd (Buffer.create 10) lexbuf) }
| eof { Eof }

and func_params buf = parse
| "->" { Func (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; func_params buf lexbuf }

and open_t buf = parse
| '\n' { Open (Buffer.contents buf |> String.trim) }
| _ as c { Buffer.add_char buf c; open_t buf lexbuf}

and element = parse
| ws* { element lexbuf }
| '<' { Tag_open }
| "</" { Tag_open_slash }
| '{' { Code_open }
| "{{" { use_view (Buffer.create 20) lexbuf }
| "<!--" { html_comment (Buffer.create 20) lexbuf }
| "<![CDATA[" { cdata (Buffer.create 10) lexbuf }
| "<![" { html_conditional_comment (Buffer.create 10) lexbuf }
| "<!" { dtd (Buffer.create 10) lexbuf }
| html_text { Html_text text }
| eof { Eof }
| _ as c { err c lexbuf }

and use_view buf = parse
| "}}" { Apply_view (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; use_view buf lexbuf }

and cdata buf = parse
| "]]>" { Cdata (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; cdata buf lexbuf }

and html_conditional_comment buf = parse
| "]>" { Html_conditional_comment (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; html_conditional_comment buf lexbuf }

and html_comment buf = parse
| "-->" { Html_comment (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; html_comment buf lexbuf }

and dtd buf = parse
| '>' { Dtd (Buffer.contents buf) }
| _ as c { Buffer.add_char buf c; dtd buf lexbuf } 

and tag_name = parse
| ws* { tag_name lexbuf }
| tag_name as name { Tag_name name }
| _ as c { err c lexbuf }

and start_tag = parse
| ws* { start_tag lexbuf }
| '>' { Tag_close }
| "/>" { Tag_slash_close }
| '=' { Tag_equals }
| '{' { code_attr (Buffer.create 10) lexbuf }
| attr_name as name { Attr_name name }
| eof { Eof }
| _ as c { err c lexbuf }

and code_attr buf = parse
| '}'      { Code_attr (Buffer.contents buf) }
| '\\' '}' { Buffer.add_char buf '}'; code_attr buf lexbuf }
| _ as c   { Buffer.add_char buf c; code_attr buf lexbuf }
| eof      { Eof }

and attribute_val = parse
| ws* { attribute_val lexbuf }
| "'" { single_quoted_attr_val (Buffer.create 10) lexbuf }
| '"' { double_quoted_attr_val (Buffer.create 10) lexbuf }
| "@{" { code_attr_val (Buffer.create 10) lexbuf }
| '@' { code_attr_val_inline (Buffer.create 10) lexbuf }
| ([^ ' ''\t' '\n' '\r' '\x09' '\'' '"' '{' '=' '<' '>' '`']+ as v) { Unquoted_attr_val v }
| eof { Eof }
| _ as c { err c lexbuf }

and single_quoted_attr_val buf = parse
| "'" { Single_quoted_attr_val (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; single_quoted_attr_val buf lexbuf }

and double_quoted_attr_val buf = parse
| '"' { Double_quoted_attr_val (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; double_quoted_attr_val buf lexbuf }

and code_attr_val buf = parse
| '}' { Code_attr_val (Buffer.contents buf) }
| eof { Eof }
| _ as c { Buffer.add_char buf c; code_attr_val buf lexbuf }

and code_attr_val_inline buf = parse
| ws+ { Code_attr_val (Buffer.contents buf) }
| '>' { Code_attr_val_internal (Buffer.contents buf, Tag_close) }
| "/>" { Code_attr_val_internal (Buffer.contents buf, Tag_slash_close) }
| _ as c { Buffer.add_char buf c; code_attr_val_inline buf lexbuf }

and code buf = parse
| "\\}" { Buffer.add_char buf '}'; code buf lexbuf }
| "\\<" { Buffer.add_char buf '<'; code buf lexbuf } 
| '}' { 
  let code_block = Buffer.contents buf in
  Buffer.clear buf;
  Code_close_block code_block }
| '<' { 
  let code_block = Buffer.contents buf in
  Buffer.clear buf;
  Code_tag_open code_block }
| "</" { 
  let code_block = Buffer.contents buf in
  Buffer.clear buf;
  Code_tag_open_slash code_block }
| '@' { code_at_inline (Buffer.create 10) lexbuf }
| "@{" { code_at_bracket (Buffer.create 10) lexbuf }
| "<text>" { 
  let code_block = Buffer.contents buf in
  Buffer.clear buf;
  let text = text (Buffer.create 10) lexbuf in
  Code_block_text (code_block, text)
  }
| _ as c  { Buffer.add_char buf c; code buf lexbuf }
| eof { Eof }

and code_at_inline buf = parse
| ws+ { Code_at (Buffer.contents buf) }
| _ as c { Buffer.add_char buf c; code_at_inline buf lexbuf }

and code_at_bracket buf = parse
| '}' { Code_at (Buffer.contents buf) }
| _ as c { Buffer.add_char buf c; code_at_bracket buf lexbuf } 

and text buf = parse
| "</text>" { Buffer.contents buf }
| _ as c { Buffer.add_char buf c; text buf lexbuf }
