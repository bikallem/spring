let nul = '\000'

type tok =
  | End_elem_start (* </ *)
  | Comment_elem (* <!-- *)
  | Start_elem (* < *)
  | Elem_slash_close (* /> *)
  | Elem_close (* > *)
  | Code_block_start (* { *)
  | Code_block_end (* } *)
  | Data (* element tag name *)
  | Equal (* = *)
  | Eoi (* End of input *)

let tok_to_string = function
  | End_elem_start -> "END_ELEM_START"
  | Comment_elem -> "COMMENT_ELEM"
  | Start_elem -> "START_ELEM"
  | Elem_slash_close -> "ELEM_SLASH_CLOSE"
  | Elem_close -> "ELEM_CLOSE"
  | Code_block_start -> "CODE_BLOCK_START"
  | Code_block_end -> "CODE_BLOCK_END"
  | Data -> "DATA"
  | Equal -> "EQUAL"
  | Eoi -> "EOF"

type input =
  { buf : Buffer.t (* buffer *)
  ; mutable line : int (* line number *)
  ; mutable col : int (* column number *)
  ; mutable c : char (* lookahead character *)
  ; mutable tok : tok (* current token *)
  ; i : unit -> char (* input function *)
  }

let next i =
  try
    let c = i.i () in
    match c with
    | '\n' ->
      i.col <- 1;
      i.line <- i.line + 1;
      i.c <- c
    | _ ->
      i.col <- i.col + 1;
      i.c <- c
  with End_of_file -> i.c <- nul

let is_ascii_whitespace = function
  | '\x09' | '\x0A' | '\x0C' | '\x0D' | '\x20' -> true
  | _ -> false

let rec skip_ws i =
  if is_ascii_whitespace i.c then (
    next i;
    skip_ws i)

let err lbl msg (i : input) =
  failwith
    (lbl ^ "(" ^ string_of_int i.line ^ "," ^ string_of_int i.col ^ ") : " ^ msg)

let expect_c c i =
  if Char.equal c i.c then ()
  else
    err "expect"
      ("expecting '" ^ Char.escaped c ^ "', got '" ^ Char.escaped i.c ^ "'")
      i

let is_alpha = function
  | 'a' .. 'z' | 'A' .. 'Z' -> true
  | _ -> false

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false

let is_alpha_num = function
  | c -> is_alpha c || is_digit c

let add_c i = Buffer.add_char i.buf i.c

let clear i = Buffer.clear i.buf

let tok i =
  skip_ws i;
  match i.c with
  | '<' -> (
    next i;
    match i.c with
    | '/' ->
      next i;
      i.tok <- End_elem_start
    | '!' ->
      expect_c '-' i;
      next i;
      expect_c '-' i;
      next i;
      i.tok <- Comment_elem
    | _ -> i.tok <- Start_elem)
  | '/' ->
    next i;
    expect_c '>' i;
    next i;
    i.tok <- Elem_slash_close
  | '>' ->
    next i;
    i.tok <- Elem_close
  | '{' -> i.tok <- Code_block_start
  | '}' -> i.tok <- Code_block_end
  | '=' -> i.tok <- Equal
  | c when c = nul -> i.tok <- Eoi
  | c when is_alpha c || c = '_' -> i.tok <- Data
  | c -> err "tok" ("unrecognized character '" ^ Char.escaped c ^ "'") i

let string_input s =
  let len = String.length s in
  let pos = ref (-1) in
  let i () =
    incr pos;
    if !pos = len then raise End_of_file else String.get s !pos
  in
  let input =
    { buf = Buffer.create 10; line = 1; col = 0; c = nul; tok = Eoi; i }
  in
  next input;
  tok input;
  input

let expect_tok tok i =
  if i.tok = tok then ()
  else
    err "expect_tok"
      ("expecting " ^ tok_to_string tok ^ " but got " ^ tok_to_string i.tok)
      i

let _pf = Printf.printf

(* Attribute parsing *)

let rec attribute_name i =
  match i.c with
  | ' ' | '=' | '>' ->
    let name = Buffer.contents i.buf in
    clear i;
    name
  | '/' -> (
    next i;
    match i.c with
    | '>' ->
      let v = Buffer.contents i.buf in
      clear i;
      i.tok <- Elem_slash_close;
      v
    | _ ->
      err "attribute_name" ("expected '>', got '" ^ Char.escaped i.c ^ "'") i)
  | ('\x00' .. '\x1F' | '\x7F' .. '\x9F' | '"' | '\'') as c ->
    err "attribute_name"
      ("invalid attribute name character '" ^ Char.escaped c ^ "'")
      i
  | _ ->
    add_c i;
    next i;
    attribute_name i

let rec quoted_attribute_value c i =
  if Char.equal i.c c then (
    let v = Buffer.contents i.buf in
    clear i;
    next i;
    v)
  else (
    add_c i;
    next i;
    quoted_attribute_value c i)

let rec unquoted_attribute_value i =
  match i.c with
  | ' ' ->
    let v = Buffer.contents i.buf in
    clear i;
    v
  | '>' ->
    let v = Buffer.contents i.buf in
    clear i;
    i.tok <- Elem_close;
    v
  | '/' -> (
    next i;
    match i.c with
    | '>' ->
      let v = Buffer.contents i.buf in
      clear i;
      i.tok <- Elem_slash_close;
      v
    | _ ->
      err "unquoted_attribute_value"
        ("expected '>', got '" ^ Char.escaped i.c ^ "'")
        i)
  | '"' | '\'' | '=' | '<' | '`' ->
    err "unquoted_attribute_value"
      ("invalid attribute value character '" ^ Char.escaped i.c ^ "'")
      i
  | c when is_ascii_whitespace c ->
    err "unquoted_attribute_value"
      ("invalid attribute value character '" ^ Char.escaped i.c ^ "'")
      i
  | _ ->
    add_c i;
    next i;
    unquoted_attribute_value i

let attribute_value i =
  let v =
    match i.c with
    | ('\'' | '"') as c ->
      next i;
      quoted_attribute_value c i
    | _ -> unquoted_attribute_value i
  in
  if String.(equal empty v) then
    err "attribute_value" "empty attribute value not allowed" i
  else v

let attributes i =
  let attributes = Queue.create () in
  let rec aux () =
    match i.tok with
    | Data -> (
      let name = attribute_name i in
      tok i;
      match i.tok with
      | Equal ->
        next i;
        skip_ws i;
        let v = attribute_value i in
        Queue.add (Node.attribute name v) attributes;
        tok i;
        aux ()
      | Elem_close | Elem_slash_close ->
        Queue.add (Node.bool_attr name) attributes
      | Data ->
        Queue.add (Node.bool_attr name) attributes;
        aux ()
      | _ ->
        err "attributes"
          ("expected token '=', '>' or '/>', got '" ^ tok_to_string i.tok ^ "'")
          i)
    | _ -> ()
  in
  aux ();
  Queue.to_seq attributes |> List.of_seq

(* Element/Code Element/Comment/Text parsing *)
let tag i =
  let rec aux () =
    match i.c with
    | c when is_alpha_num c ->
      add_c i;
      next i;
      aux ()
    | '_' | '\'' | '.' ->
      add_c i;
      next i;
      aux ()
    | _ ->
      let tag = Buffer.contents i.buf in
      clear i;
      tag
  in
  expect_tok Data i;
  add_c i;
  next i;
  aux ()

let end_elem start_tag i =
  let tag = tag i in
  tok i;
  expect_tok Elem_close i (* > *);
  if String.equal start_tag tag then ()
  else
    err "close_tag"
      ("expected closed tag '" ^ start_tag ^ "', got '" ^ tag ^ "'")
      i

let is_void_elem = function
  | "area"
  | "base"
  | "br"
  | "col"
  | "embed"
  | "hr"
  | "img"
  | "input"
  | "link"
  | "meta"
  | "param"
  | "source"
  | "track"
  | "wbr" -> true
  | _ -> false

let void_elem_close i =
  match i.tok with
  | Elem_close | Elem_slash_close -> ()
  | tok ->
    err "void_elem_close"
      ("expecting '" ^ tok_to_string Elem_close ^ "' or '"
      ^ tok_to_string Elem_slash_close
      ^ "', got '" ^ tok_to_string tok ^ "'.")
      i

let rec element i =
  expect_tok Start_elem i;
  tok i;
  expect_tok Data i;
  let tag_name = tag i in
  tok i;
  let attributes = attributes i in
  if is_void_elem tag_name then (
    void_elem_close i;
    Node.void ~attributes tag_name)
  else
    match i.tok with
    | Elem_slash_close -> Node.element ~attributes tag_name (* no children *)
    | Elem_close -> (
      tok i;
      match i.tok with
      | End_elem_start (* </ *) ->
        tok i;
        end_elem tag_name i;
        Node.element ~attributes tag_name
      | Start_elem | Code_block_start ->
        let children = children tag_name i in
        Node.element ~attributes ~children tag_name
      | tok ->
        err "element"
          ("expecting '"
          ^ tok_to_string End_elem_start
          ^ "' or '" ^ tok_to_string Start_elem ^ "', got '" ^ tok_to_string tok
          ^ "'")
          i)
    | tok ->
      err "element"
        ("expecting '"
        ^ tok_to_string Elem_slash_close
        ^ "' or '" ^ tok_to_string Elem_close ^ "', got '" ^ tok_to_string tok
        ^ "'")
        i

and children start_tag i =
  let rec aux acc =
    match i.tok with
    | Start_elem -> aux (element i :: acc)
    | End_elem_start ->
      tok i;
      end_elem start_tag i;
      acc
    | Code_block_start -> aux (code_element i :: acc)
    | _ -> acc
  in
  aux []

(* OCaml code blocks starts with '{' and ends with '}' *)
and code_element i =
  let rec aux parsing_code_block q =
    match i.c with
    | '}' ->
      prepend_code_block parsing_code_block i q;
      next i;
      i.tok <- Code_block_end;
      q
    | '<' ->
      prepend_code_block parsing_code_block i q;
      next i;
      i.tok <- Start_elem;
      Queue.add (element i) q;
      aux false q
    | _ ->
      add_c i;
      next i;
      aux true q
  and prepend_code_block is_parsing_code_block i q =
    if is_parsing_code_block then (
      let code = Buffer.contents i.buf in
      clear i;
      Queue.add (Node.code_block code) q)
  in
  expect_tok Code_block_start i;
  next i;
  let code_blocks =
    aux false (Queue.create ()) |> Queue.to_seq |> List.of_seq
  in
  expect_tok Code_block_end i;
  tok i;
  Node.code_element code_blocks

let root i = element i
