let nul = '\000'

type tok =
  | Start_elem (* < *)
  | Elem_close (* > - Both start end end element *)
  | Start_elem_slash_close (* /> *)
  | End_elem_start (* </ *)
  | Comment_elem_start (* <!-- *)
  | Comment_elem_end (* --> *)
  | Code_block_start (* { *)
  | Code_block_end (* } *)
  | Data of char (* element tag name *)
  | SPACE (* whitespace *)
  | Equal (* = *)
  | Eoi (* End of input *)

let tok_to_string = function
  | Start_elem -> "START_ELEM"
  | Start_elem_slash_close -> "START_ELEM_SLASH_CLOSE"
  | End_elem_start -> "END_ELEM_START"
  | Comment_elem_start -> "COMMENT_ELEM_START"
  | Comment_elem_end -> "COMMENT_ELEM_END"
  | Elem_close -> "ELEM_CLOSE"
  | Code_block_start -> "CODE_BLOCK_START"
  | Code_block_end -> "CODE_BLOCK_END"
  | Data c -> "DATA " ^ Char.escaped c
  | SPACE -> "SPACE"
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

let is_ascii_whitespace = function
  | '\x09' | '\x0A' | '\x0C' | '\x0D' | '\x20' -> true
  | _ -> false

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

let add_c c i = Buffer.add_char i.buf c

let clear i = Buffer.clear i.buf

let _pf = Printf.printf

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

let tok i =
  match i.c with
  | '<' -> (
    next i;
    match i.c with
    | '/' ->
      i.tok <- End_elem_start;
      next i
    | '!' ->
      next i;
      expect_c '-' i;
      next i;
      expect_c '-' i;
      i.tok <- Comment_elem_start;
      next i
    | _ -> i.tok <- Start_elem)
  | '/' ->
    next i;
    expect_c '>' i;
    i.tok <- Start_elem_slash_close;
    next i
  | '>' ->
    i.tok <- Elem_close;
    next i
  | '{' ->
    i.tok <- Code_block_start;
    next i
  | '}' ->
    i.tok <- Code_block_end;
    next i
  | '=' ->
    i.tok <- Equal;
    next i
  | c when is_ascii_whitespace c ->
    let rec aux () =
      match i.c with
      | c when is_ascii_whitespace c ->
        next i;
        aux ()
      | _ -> ()
    in
    next i;
    aux ();
    i.tok <- SPACE
  | c when c = nul -> i.tok <- Eoi
  | c ->
    i.tok <- Data c;
    next i

let rec skip_ws i =
  match i.tok with
  | SPACE ->
    tok i;
    skip_ws i
  | _ -> ()

(* use this to move from one token to another. *)

let string_input s =
  let len = String.length s in
  let pos = ref (-1) in
  let i () =
    incr pos;
    if !pos >= len then raise End_of_file else String.get s !pos
  in
  let input =
    { buf = Buffer.create 10; line = 1; col = 0; c = i (); tok = Eoi; i }
  in
  tok input;
  input

let expect_tok tok i =
  if i.tok = tok then ()
  else
    err "expect_tok"
      ("expecting " ^ tok_to_string tok ^ " but got " ^ tok_to_string i.tok)
      i

(* Attribute parsing *)

let rec attribute_name i =
  match i.c with
  | '\x00' .. '\x1F' | '\x7F' .. '\x9F' | '"' | '\'' | '>' | '/' | '=' | ' ' ->
    let nm = Buffer.contents i.buf in
    clear i;
    (*     _pf "\nname:%s, '%c'%!" nm i.c; *)
    tok i;
    nm
  | _ ->
    (*     _pf "\nname:%c%!" i.c; *)
    add_c i.c i;
    next i;
    attribute_name i

let rec quoted_attribute_value c i =
  if Char.equal i.c c then (
    let v = Buffer.contents i.buf in
    clear i;
    next i;
    tok i;
    v)
  else (
    add_c i.c i;
    next i;
    quoted_attribute_value c i)

let rec unquoted_attribute_value i =
  match i.c with
  | c when is_ascii_whitespace c || c = '>' || c = '/' ->
    let v = Buffer.contents i.buf in
    clear i;
    tok i;
    v
  | '"' | '\'' | '=' | '<' | '`' ->
    err "unquoted_attribute_value"
      ("invalid attribute value character '" ^ Char.escaped i.c ^ "'")
      i
  | _ ->
    add_c i.c i;
    next i;
    unquoted_attribute_value i

let rec code_attribute i =
  match i.c with
  | '}' ->
    let v = Buffer.contents i.buf in
    clear i;
    next i;
    tok i;
    v
  | _ ->
    add_c i.c i;
    next i;
    code_attribute i

let attribute_value i =
(*   _pf "\nattr value: %s%!" (tok_to_string i.tok); *)
  match i.tok with
  | Equal -> (
    tok i;
    skip_ws i;
    match i.tok with
    | Data c when c = '\'' ->
      let v = quoted_attribute_value c i in
      Some (Node.single_quoted_attribute_value v)
    | Data c when c = '"' ->
      let v = quoted_attribute_value c i in
      Some (Node.double_quoted_attribute_value v)
    | Data c ->
      add_c c i;
      let v = unquoted_attribute_value i in
      Some (Node.unquoted_attribute_value v)
    | Code_block_start ->
      let v = code_attribute i in
      Some (Node.code_attribute_value v)
    | _ ->
      err "attribute_value"
        ("expected ' \" '{', got'" ^ tok_to_string i.tok ^ "'")
        i)
  | _ -> None

let attributes i =
  let attributes = Queue.create () in
  let rec aux () =
    skip_ws i;
    match i.tok with
    | Code_block_start ->
      let v = code_attribute i in
      Queue.add (Node.code_attribute v) attributes;
      aux ()
    | Data c -> (
      add_c c i;
      let name = attribute_name i in
(*       _pf "\nattribute name: %s%!" name; *)
      skip_ws i;
      match attribute_value i with
      | Some v ->
        Queue.add (Node.attribute name v) attributes;
        aux ()
      | None ->
        Queue.add (Node.bool_attr name) attributes;
        aux ())
    | _ -> ()
  in
  aux ();
  if Queue.length attributes > 0 then Queue.to_seq attributes |> List.of_seq
  else []

(* Element/Code Element/Comment/Text parsing *)
let tag i =
  let rec aux () =
    match i.tok with
    | Data c when is_alpha_num c || c = '_' || c = '\'' || c = '.' ->
      add_c c i;
      tok i;
      aux ()
    | _ ->
      let tag = Buffer.contents i.buf in
      clear i;
      tag
  in
  skip_ws i;
  match i.tok with
  | Data c when is_alpha c || c = '_' ->
    add_c c i;
    tok i;
    aux ()
  | Data c ->
    err "tag"
      ("tag name starts with alpha or '_' character, got '" ^ Char.escaped c
     ^ "'")
      i
  | _ -> err "tag" ("expected DATA token, got '" ^ tok_to_string i.tok ^ "'") i

let end_elem start_tag i =
  let tag = tag i in
  expect_tok Elem_close i (* > *);
  if String.equal start_tag tag then ()
  else
    err "close_tag"
      ("expected closed tag '" ^ start_tag ^ "', got '" ^ tag ^ "'")
      i

(* <div > or <div /> *)
let start_tag i =
  skip_ws i;
  expect_tok Start_elem i;
  tok i;
  let tag_name = tag i in
  skip_ws i;
  let attributes = attributes i in
  skip_ws i;
  match i.tok with
  | Start_elem_slash_close ->
    tok i;
    (tag_name, attributes, false)
  | Elem_close ->
    tok i;
    (tag_name, attributes, true)
  | tok ->
    err "element"
      ("expecting '"
      ^ tok_to_string Start_elem_slash_close
      ^ "' or '" ^ tok_to_string Elem_close ^ "', got '" ^ tok_to_string tok
      ^ "'")
      i

(* </div> *)
let end_tag tag_name i =
  skip_ws i;
  expect_tok End_elem_start i;
  tok i;
  let tag = tag i in
  expect_tok Elem_close i (* > *);
  tok i;
  if String.equal tag_name tag then ()
  else
    err "close_tag"
      ("expected closed tag '" ^ tag_name ^ "', got '" ^ tag ^ "'")
      i

let rec element i =
  let tag_name, attributes, has_children = start_tag i in
  if has_children then (
(*     _pf "\nelement: start children %s%!" tag_name; *)
    let children = children i in
    let e = Node.element ~attributes ~children tag_name in
(*     _pf "\nelement: end children: %s:%d%!" tag_name (List.length children); *)
    end_tag tag_name i;
    e)
  else Node.element ~attributes ~children:[] tag_name

and children i =
  let children = Queue.create () in
  let rec aux () =
(*     _pf "\nchildren: %s%!" (tok_to_string i.tok); *)
    match i.tok with
    | Start_elem ->
      let el = element i in
      Queue.add el children;
      aux ()
    | Code_block_start ->
      let el = code_element i in
      Queue.add el children;
      aux ()
    | Comment_elem_start ->
      () (*
      Queue.add (comment_element i) children;
      aux ()
*)
    | _ -> ()
  in
  aux ();
  Queue.to_seq children |> List.of_seq

(* { ... } *)
and code_element i =
  let code_blocks = Queue.create () in
  let rec aux parsing_code_block =
    (*     _pf "\ncode_element: %c%!" i.c; *)
    match i.c with
    | '}' ->
      prepend_code_block parsing_code_block i;
      next i;
      tok i
    | '<' ->
      prepend_code_block parsing_code_block i;
      next i;
      i.tok <- Start_elem;
      Queue.add (element i) code_blocks;
      aux false
    | _ ->
      add_c i.c i;
      next i;
      aux true
  and prepend_code_block is_parsing_code_block i =
    if is_parsing_code_block then (
      let code = Buffer.contents i.buf in
      clear i;
      Queue.add (Node.code_block code) code_blocks)
  in
  expect_tok Code_block_start i;
  add_c i.c i;
  next i;
  aux false;
  let code_blocks = Queue.to_seq code_blocks |> List.of_seq in
  Node.code_element code_blocks

and comment_element i =
  (*   _pf "%c%!" i.c; *)
  match i.c with
  | '-' -> (
    next i;
    (*     _pf "%c%!" i.c; *)
    match i.c with
    | '-' -> (
      next i;
      (*       _pf "%c%!" i.c; *)
      match i.c with
      | '>' ->
        (*         _pf "end\n%!"; *)
        let txt = Buffer.contents i.buf in
        clear i;
        next i;
        tok i;
        Node.comment txt
      | _ ->
        Buffer.add_char i.buf '-';
        Buffer.add_char i.buf '-';
        (*         add_c i; *)
        next i;
        comment_element i)
    | _ ->
      Buffer.add_char i.buf '-';
      (*       add_c i; *)
      next i;
      comment_element i)
  | _ ->
    (*     add_c i; *)
    next i;
    comment_element i

let root i =
  let e = element i in
  e
