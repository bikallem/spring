let nul = '\000'

type tok =
  | End_elem_start (* </ *)
  | Comment_elem (* <!-- *)
  | Start_elem (* < *)
  | Elem_slash_close (* /> *)
  | Elem_close (* > *)
  | Tag (* element tag name *)
  | Eoi (* End of input *)

let tok_to_string = function
  | End_elem_start -> "</"
  | Comment_elem -> "<!--"
  | Start_elem -> "<"
  | Elem_slash_close -> "/>"
  | Elem_close -> ">"
  | Tag -> "TAG"
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

let rec skip_ws i =
  match i.c with
  | '\t' | ' ' | '\n' | '\r' ->
    next i;
    skip_ws i
  | _ -> ()

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
  | c when is_alpha c || c = '_' -> i.tok <- Tag
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
  add_c i;
  next i;
  aux ()

let expect_tok tok i =
  if i.tok = tok then ()
  else
    err "expect_tok"
      ("expecting " ^ tok_to_string tok ^ " but got " ^ tok_to_string i.tok)
      i

let _pf = Printf.printf

(* </div> *)
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
  tok i;
  match i.tok with
  | Elem_close | Elem_slash_close -> ()
  | tok ->
    err "void_elem_close"
      ("expecting '" ^ tok_to_string Elem_close ^ "' or '"
      ^ tok_to_string Elem_slash_close
      ^ "', got '" ^ tok_to_string tok ^ "'.")
      i

let rec element i =
  expect_tok Tag i;
  let tag_name = tag i in
  if is_void_elem tag_name then (
    void_elem_close i;
    Node.void tag_name)
  else (
    tok i;
    match i.tok with
    | Elem_slash_close -> Node.element tag_name (* no children *)
    | Elem_close -> (
      tok i;
      match i.tok with
      | End_elem_start (* </ *) ->
        end_elem tag_name i;
        Node.element tag_name
      | Start_elem (* < *) ->
        let children = children i in
        end_elem tag_name i;
        Node.element ~children tag_name
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
        i)

and children i =
  let rec aux acc =
    match i.tok with
    | Start_elem -> aux (element i :: acc)
    | _ -> acc
  in
  aux []

let root i =
  expect_tok Start_elem i;
  tok i;
  element i
