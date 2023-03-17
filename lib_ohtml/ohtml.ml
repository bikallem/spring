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
  | Parser1.START_ELEM -> "START_ELEM"
  | TAG_NAME name -> "TAG_NAME " ^ name
  | ELEM_CLOSE -> "ELEM_CLOSE"
  | START_ELEM_SLASH_CLOSE -> "START_ELEM_SLASH_CLOSE"
  | END_ELEM_START -> "END_ELEM_START"
  | CODE_BLOCK _ -> "CODE_BLOCK"
  | EQUAL -> "EQUAL"
  | EOF -> "EOF"
  | _ -> failwith "x"

type lexer = Lexing.lexbuf -> Parser1.token

type input =
  { lexbuf : Lexing.lexbuf
  ; tokenizer : lexer Stack.t
  }

let tokenize i =
  let f = Stack.top i.tokenizer in
  f i.lexbuf

let rec loop (i : input) checkpoint =
  match checkpoint with
  | I.InputNeeded _env ->
    let token = tokenize i in
    (*     Printf.printf "\n%s%!" (tok_to_string token); *)
    (match token with
    | Parser1.EQUAL -> Stack.push Lexer.attribute_val i.tokenizer
    | Parser1.ATTR_VAL _ | ATTR_VAL_CODE _ ->
      ignore (Stack.pop i.tokenizer : lexer)
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
