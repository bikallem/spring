module Doc = Doc
module I = Parser.MenhirInterpreter

exception Syntax_error of int * int

let get_lexing_position lexbuf =
  let p = Lexing.lexeme_start_p lexbuf in
  let line_number = p.Lexing.pos_lnum in
  let column = p.Lexing.pos_cnum - p.Lexing.pos_bol + 1 in
  (line_number, column)

[@@@warning "-32"]

let tok_to_string = function
  | Parser.Tag_open -> "TAG_OPEN"
  | Tag_name name -> "TAG_NAME " ^ name
  | Tag_close -> "TAG_CLOSE"
  | Tag_slash_close -> "TAG_SLASH_CLOSE"
  | Tag_open_slash -> "TAG_OPEN_SLASH"
  | Tag_equals -> "TAG_EQUALS"
  | Code_open -> "CODE_OPEN"
  | Code_block s -> "CODE_BLOCK " ^ s
  | Code_close -> "CODE_CLOSE"
  | Code_close_block s -> "CODE_CLOSE_BLOCK " ^ s
  | Code_tag_open _ -> "CODE_TAG_OPEN"
  | Code_tag_open_slash _ -> "CODE_TAG_OPEN_SLASH"
  | Code_block_text (code_block, text) ->
    "CODE_TEXT (" ^ code_block ^ ", " ^ text ^ ")"
  | Attr_name _ -> "ATTR_NAME"
  | Single_quoted_attr_val _ -> "SINGLE_QUOTED_ATTRIBUTE_VAL"
  | Double_quoted_attr_val _ -> "DOUBLE_QUOTED_ATTRIBUTE_VAL"
  | Unquoted_attr_val _ -> "UNQUOTED_ATTRIBUTE_VAL"
  | Code_attr_val v -> "CODE_ATTR_VAL " ^ v
  | Code_attr_val_internal _ -> "CODE_ATTR_VAL_INTERNAL"
  | Code_attr _ -> "CODE_ATTR"
  | Html_comment _ -> "HTML_COMMENT"
  | Html_conditional_comment _ -> "HTML_CONDITIONAL_COMMENT"
  | Cdata _ -> "CDATA"
  | Dtd _ -> "DTD"
  | Html_text _ -> "HTML_TEXT"
  | Func _ -> "FUNC"
  | Func_empty _ -> "FUNC_EMPTY"
  | Open _ -> "OPEN"
  | Apply_view _ -> "APPLY_VIEW"
  | Code_at _ -> "CODE_AT"
  | Code_at_internal _ -> "CODE_AT_INTERNAL"
  | Eof -> "EOF"

type lexer = Lexing.lexbuf -> Parser.token

type input =
  { lexbuf : Lexing.lexbuf
  ; tokenizer : lexer Stack.t
  ; mutable next_tok : Parser.token option
  }

let tokenize i =
  match i.next_tok with
  | Some tok ->
    i.next_tok <- None;
    tok
  | None ->
    let f = Stack.top i.tokenizer in
    f i.lexbuf

let pop i = ignore (Stack.pop i.tokenizer : lexer)
let push i lexer = Stack.push lexer i.tokenizer

let rec loop (i : input) checkpoint =
  match checkpoint with
  | I.InputNeeded _env ->
    let token = ref (tokenize i) in
    (* Printf.printf "\n%s%!" (tok_to_string !token); *)
    (match !token with
    | Parser.Func _ ->
      pop i;
      push i Lexer.element
    | Func_empty tok ->
      pop i;
      push i Lexer.element;
      token := Func "";
      i.next_tok <- Some tok
    | Code_open -> push i @@ Lexer.code (Buffer.create 10)
    | Code_close -> pop i
    | Code_close_block code_block ->
      token := Code_block code_block;
      i.next_tok <- Some Code_close
    | Code_tag_open code_block ->
      token := Code_block code_block;
      i.next_tok <- Some Tag_open
    | Code_tag_open_slash code_block ->
      token := Code_block code_block;
      i.next_tok <- Some Tag_open_slash
    | Code_block_text (code_block, text) ->
      token := Code_block code_block;
      i.next_tok <- Some (Html_text text)
    | Tag_equals -> push i Lexer.attribute_val
    | Code_at_internal (code, tok) ->
      token := Code_at code;
      i.next_tok <- Some tok
    | Code_attr_val_internal (code, tok) ->
      token := Code_attr_val code;
      i.next_tok <- Some tok;
      pop i
    | Unquoted_attr_val _
    | Single_quoted_attr_val _
    | Double_quoted_attr_val _
    | Code_attr_val _ -> pop i
    | Tag_open | Tag_open_slash -> push i Lexer.tag_name
    | Tag_name _ ->
      pop i;
      push i Lexer.start_tag
    | Tag_close | Tag_slash_close -> pop i
    | _ -> ());
    let startp = i.lexbuf.lex_start_p and endp = i.lexbuf.lex_curr_p in
    let checkpoint = I.offer checkpoint (!token, startp, endp) in
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
  let i = { lexbuf; tokenizer; next_tok = None } in
  push i Lexer.element;
  let checkpoint = Parser.Incremental.doc lexbuf.lex_curr_p in
  loop i checkpoint

let parse_doc_string s =
  let lexbuf = Lexing.from_string s in
  let tokenizer = Stack.create () in
  let i = { lexbuf; tokenizer; next_tok = None } in
  push i Lexer.func;
  let checkpoint = Parser.Incremental.doc lexbuf.lex_curr_p in
  loop i checkpoint

let parse_doc filepath =
  In_channel.with_open_text filepath (fun ch ->
      let lexbuf = Lexing.from_channel ch in
      let tokenizer = Stack.create () in
      let i = { lexbuf; tokenizer; next_tok = None } in
      push i Lexer.func;
      let checkpoint = Parser.Incremental.doc lexbuf.lex_curr_p in
      loop i checkpoint)

let gen_ocaml ~write_ln (doc : Doc.doc) =
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
    | Code l -> code l
    | Apply_view view_name -> write_ln @@ "(" ^ view_name ^ ") b;"
    | Html_text text -> write_ln @@ {|Buffer.add_string b "|} ^ text ^ {|";|}
    | Html_comment comment ->
      write_ln @@ {|Buffer.add_string b "<!-- |} ^ comment ^ {| -->";|}
    | Html_conditional_comment comment ->
      write_ln @@ {|Buffer.add_string b "<![ |} ^ comment ^ {| ]>";|}
    | Cdata cdata ->
      write_ln @@ {|Buffer.add_string b "<![CDATA[ |} ^ cdata ^ {| ]]>";|}
  and gen_attribute = function
    | Doc.Bool_attribute attr ->
      write_ln @@ {|Buffer.add_string b " |} ^ attr ^ {|";|}
    | Doc.Double_quoted_attribute (nm, v) ->
      write_ln @@ {|Buffer.add_string b " |} ^ nm ^ {|=\"|} ^ v ^ {|\"";|}
    | Doc.Single_quoted_attribute (nm, v) ->
      write_ln @@ {|Buffer.add_string b " |} ^ nm ^ {|='|} ^ v ^ {|'";|}
    | Doc.Unquoted_attribute (nm, v) ->
      write_ln @@ {|Buffer.add_string b " |} ^ nm ^ {|=|} ^ v ^ {|";|}
    | Doc.Name_code_val_attribute (nm, code) ->
      write_ln @@ {|Buffer.add_string b " |} ^ nm ^ {|=\"";|};
      write_ln @@ {|Buffer.add_string b @@ Spring.Ohtml.escape_html (|} ^ code
      ^ {|);|};
      write_ln @@ {|Buffer.add_string b "\"";|}
    | Doc.Code_attribute code ->
      write_ln @@ {|Buffer.add_char b ' ';|};
      write_ln @@ {|Spring.Ohtml.write_attribute (|} ^ code ^ {| ) b;|}
  and code l =
    let rec aux = function
      | Doc.Code_block block -> write_ln @@ block
      | Code_at string_val ->
        write_ln @@ {|Buffer.add_string b (Spring.Ohtml.escape_html @@ |}
        ^ string_val ^ {|);|}
      | Code_text txt -> write_ln @@ {|Buffer.add_string b "|} ^ txt ^ {|";|}
      | Code_element { tag_name; children; attributes } ->
        write_ln @@ {|Buffer.add_string b "<|} ^ tag_name ^ {|";|};
        List.iter (fun attr -> gen_attribute attr) attributes;
        if [] = children then write_ln {|Buffer.add_string b "/>";|}
        else (
          write_ln {|Buffer.add_string b ">";|};
          List.iter (fun child -> aux child) children;
          write_ln @@ {|Buffer.add_string b "</|} ^ tag_name ^ {|>";|})
    in
    write_ln @@ "(";
    List.iter aux l;
    write_ln @@ ");"
  in
  let fun_args =
    match doc.fun_args with
    | None -> ""
    | Some v -> v
  in
  let fun_decl = Printf.sprintf "let v %s (b:Buffer.t) : unit = " fun_args in
  List.iter (fun o -> write_ln @@ "open " ^ o) doc.opens;
  write_ln fun_decl;
  Option.iter
    (fun doctype -> write_ln @@ {|Buffer.add_string b "<!|} ^ doctype ^ {|>";|})
    doc.doctype;
  gen_element doc.root
