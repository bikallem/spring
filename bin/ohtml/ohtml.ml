module Node = Node
module Doc = Doc
module I = Parser1.MenhirInterpreter

exception Syntax_error of int * int

let get_lexing_position lexbuf =
  let p = Lexing.lexeme_start_p lexbuf in
  let line_number = p.Lexing.pos_lnum in
  let column = p.Lexing.pos_cnum - p.Lexing.pos_bol + 1 in
  (line_number, column)

[@@@warning "-32"]

let tok_to_string = function
  | Parser1.TAG_OPEN -> "TAG_OPEN"
  | TAG_NAME name -> "TAG_NAME " ^ name
  | TAG_CLOSE -> "TAG_CLOSE"
  | TAG_SLASH_CLOSE -> "TAG_SLASH_CLOSE"
  | TAG_OPEN_SLASH -> "TAG_OPEN_SLASH"
  | TAG_EQUALS -> "TAG_EQUALS"
  | CODE_OPEN -> "CODE_OPEN"
  | CODE_BLOCK s -> "CODE_BLOCK " ^ s
  | CODE_CLOSE -> "CODE_CLOSE"
  | ATTR_VAL _ -> "ATTR_VAL"
  | ATTR_VAL_CODE _ -> "ATTR_VAL_CODE"
  | CODE_ATTR _ -> "CODE_ATTR"
  | HTML_COMMENT _ -> "HTML_COMMENT"
  | HTML_CONDITIONAL_COMMENT _ -> "HTML_CONDITIONAL_COMMENT"
  | CDATA _ -> "CDATA"
  | DTD _ -> "DTD"
  | HTML_TEXT s -> "HTML_TEXT " ^ s
  | FUNC _ -> "PARAM "
  | EOF -> "EOF"

type lexer = Lexing.lexbuf -> Parser1.token
type input = { lexbuf : Lexing.lexbuf; tokenizer : lexer Stack.t }

let tokenize i =
  let f = Stack.top i.tokenizer in
  f i.lexbuf

let pop i = ignore (Stack.pop i.tokenizer : lexer)
let push i lexer = Stack.push lexer i.tokenizer

let rec loop (i : input) checkpoint =
  match checkpoint with
  | I.InputNeeded _env ->
    let token = tokenize i in
    (* Printf.printf "\n%s%!" (tok_to_string token); *)
    (match token with
    | Parser1.FUNC _ -> push i Lexer.element
    | Parser1.CODE_OPEN -> push i Lexer.code
    | Parser1.CODE_CLOSE -> pop i
    | Parser1.TAG_EQUALS -> push i Lexer.attribute_val
    | Parser1.ATTR_VAL _ | ATTR_VAL_CODE _ -> pop i
    | Parser1.TAG_OPEN | TAG_OPEN_SLASH -> push i Lexer.tag
    | Parser1.TAG_CLOSE | TAG_SLASH_CLOSE -> pop i
    | _ -> ());
    let startp = i.lexbuf.lex_start_p and endp = i.lexbuf.lex_curr_p in
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

let parse_element s =
  let lexbuf = Lexing.from_string s in
  let tokenizer = Stack.create () in
  let i = { lexbuf; tokenizer } in
  push i Lexer.element;
  let checkpoint = Parser1.Incremental.doc lexbuf.lex_curr_p in
  loop i checkpoint

let parse_doc_string s =
  let lexbuf = Lexing.from_string s in
  let tokenizer = Stack.create () in
  let i = { lexbuf; tokenizer } in
  push i Lexer.func;
  let checkpoint = Parser1.Incremental.doc lexbuf.lex_curr_p in
  loop i checkpoint

let escape_html txt =
  let escaped = Buffer.create 10 in
  String.iter
    (function
      | '&' -> Buffer.add_string escaped "&amp;"
      | '<' -> Buffer.add_string escaped "&lt;"
      | '>' -> Buffer.add_string escaped "&gt;"
      | '"' -> Buffer.add_string escaped "&quot;"
      | '\039' -> Buffer.add_string escaped "&#x27;"
      | '\047' -> Buffer.add_string escaped "&#x2F;"
      | ('\x00' .. '\x1F' as c) | ('\x7F' as c) ->
        Buffer.add_string escaped ("&#" ^ string_of_int (Char.code c) ^ ";")
      | c -> Buffer.add_char escaped c)
    txt;
  Buffer.contents escaped

let gen_ocaml ~fun_name ~write_ln (doc : Doc.doc) =
  let rec gen_element el =
    match el with
    | Doc.Element { tag_name; children; attributes } ->
      write_ln @@ {|Buffer.add_string b "<|} ^ tag_name ^ {|";|};
      List.iter (fun attr -> gen_attribute attr) attributes;
      if [] = children then write_ln {|Buffer.add_string b "/>";|}
      else (
        write_ln {|Buffer.add_string b ">";|};
        List.iter (fun child -> gen_element child) children;
        write_ln @@ {|Buffer.add_string b "</|} ^ tag_name ^ {|>";|})
    | Html_text text -> write_ln @@ {|Buffer.add_string b "|} ^ text ^ {|";|}
    | _ -> ()
  and gen_attribute = function
    | Doc.Bool_attribute attr ->
      write_ln @@ {|Buffer.add_string b " |} ^ attr ^ {|";|}
    | Doc.Name_val_attribute (nm, v) ->
      write_ln @@ {|Buffer.add_string b " |} ^ nm ^ {|=|} ^ v ^ {|";|}
    | _ -> ()
  in
  let fun_args =
    match doc.fun_args with
    | None -> ""
    | Some v -> v
  in
  let fun_decl =
    Printf.sprintf "let %s %s : Spring.Ohtml.html_writer = \nfun b -> " fun_name fun_args
  in
  write_ln fun_decl;
  gen_element doc.root
