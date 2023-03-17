module Node = Node
module Node2 = Node2
module Parser1 = Parser1
module I = Parser1.MenhirInterpreter

exception Syntax_error of int * int

let get_lexing_position lexbuf =
  let p = Lexing.lexeme_start_p lexbuf in
  let line_number = p.Lexing.pos_lnum in
  let column = p.Lexing.pos_cnum - p.Lexing.pos_bol + 1 in
  (line_number, column)

let tok_to_string = function
  | Parser1.TAG_OPEN -> "TAG_OPEN"
  | TAG_NAME name -> "TAG_NAME " ^ name
  | TAG_CLOSE -> "TAG_CLOSE"
  | TAG_SLASH_CLOSE -> "TAG_SLASH_CLOSE"
  | TAG_OPEN_SLASH -> "TAG_OPEN_SLASH"
  | TAG_EQUALS -> "TAG_EQUALS"
  | CODE_BLOCK _ -> "CODE_BLOCK"
  | ATTR_VAL _ -> "ATTR_VAL"
  | ATTR_VAL_CODE _ -> "ATTR_VAL_CODE"
  | CODE_ATTR _ -> "CODE_ATTR"
  | HTML_COMMENT _ -> "HTML_COMMENT"
  | HTML_CONDITIONAL_COMMENT _ -> "HTML_CONDITIONAL_COMMENT"
  | CDATA _ -> "CDATA"
  | DTD _ -> "DTD"
  | HTML_TEXT _ -> "HTML_TEXT"
  | EOF -> "EOF"

type lexer = Lexing.lexbuf -> Parser1.token

type input =
  { lexbuf : Lexing.lexbuf
  ; tokenizer : lexer Stack.t
  }

let tokenize i =
  let f = Stack.top i.tokenizer in
  f i.lexbuf

let pop i = ignore (Stack.pop i.tokenizer : lexer)

let push i lexer = Stack.push lexer i.tokenizer

let rec loop (i : input) checkpoint =
  match checkpoint with
  | I.InputNeeded _env ->
    let token = tokenize i in
    (*     Printf.printf "\n%s%!" (tok_to_string token); *)
    (match token with
    | Parser1.TAG_EQUALS -> push i Lexer.attribute_val
    | Parser1.ATTR_VAL _ | ATTR_VAL_CODE _ -> pop i
    | Parser1.TAG_OPEN | TAG_OPEN_SLASH -> push i Lexer.tag
    | Parser1.TAG_CLOSE | TAG_SLASH_CLOSE -> pop i
    | _ -> ());
    let startp = i.lexbuf.lex_start_p
    and endp = i.lexbuf.lex_curr_p in
    let checkpoint = I.offer checkpoint (token, startp, endp) in
    loop i checkpoint
  | I.Shifting _ | I.AboutToReduce _ ->
    let checkpoint = I.resume checkpoint in
    loop i checkpoint
  | I.HandlingError _env ->
    let line, pos = get_lexing_position i.lexbuf in
    raise (Syntax_error (line, pos))
  | I.Accepted v -> v
  | I.Rejected -> assert false

let parse s =
  let lexbuf = Lexing.from_string s in
  let tokenizer = Stack.create () in
  Stack.push Lexer.element tokenizer;
  let i = { lexbuf; tokenizer } in
  let checkpoint = Parser1.Incremental.doc lexbuf.lex_curr_p in
  loop i checkpoint
