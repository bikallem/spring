{
  open Parser1
  exception Error of string

  let err lexbuf = 
    let offset = Lexing.lexeme_start lexbuf |> string_of_int in
    failwith @@ "At offset " ^ offset ^ ": unexpected character.\n"
}

let alpha = ['a'-'z'] | ['A'-'Z']
let num = ['0'-'9']
let tag_name = (alpha | '_') (alpha | num | '_' | '\'' | '.')*
let ws = [ ' ' '\t' '\n' '\r' '\x09']

rule element = parse
| ws { element lexbuf }
| '<' { START_ELEM }
| '>' { ELEM_CLOSE }
| "/>" { START_ELEM_SLASH_CLOSE }
| "</" { END_ELEM_START }
| '{' { code_block (Buffer.create 10) lexbuf }
| '=' { EQUAL }
| tag_name as name { TAG_NAME name }
| eof { EOF }
| _ { err lexbuf }

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
| _ { err lexbuf }
