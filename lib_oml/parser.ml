let nul = '\000'

type input =
  { buf : Buffer.t
  ; mutable line : int
  ; mutable col : int
  ; mutable c : char
  ; i : unit -> char
  }

let next i =
  let c = i.i () in
  match c with
  | '\n' ->
    i.col <- 1;
    i.line <- i.line + 1;
    i.c <- c
  | _ ->
    i.col <- i.col + 1;
    i.c <- c

let string_input s =
  let len = String.length s in
  let pos = ref (-1) in
  let i () =
    incr pos;
    if !pos = len then raise End_of_file else String.get s !pos
  in
  let input = { buf = Buffer.create 10; line = 1; col = 0; c = nul; i } in
  next input;
  input

let add_c i = Buffer.add_char i.buf i.c

let err lbl msg (i : input) =
  failwith
    (lbl ^ "(" ^ string_of_int i.line ^ "," ^ string_of_int i.col ^ ") : " ^ msg)

let clear i = Buffer.clear i.buf

let is_alpha = function
  | 'a' .. 'z' | 'A' .. 'Z' -> true
  | _ -> false

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false

let is_alpha_num = function
  | c -> is_alpha c || is_digit c

let rec skip_ws i =
  match i.c with
  | '\t' | ' ' | '\n' | '\r' ->
    next i;
    skip_ws i
  | _ -> ()

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
  match i.c with
  | c when is_alpha c || c = '_' ->
    add_c i;
    next i;
    aux ()
  | _ ->
    err "start_tag"
      ("tag name must start with an alphabet or '_' character, got '"
     ^ Char.escaped i.c ^ "'")
      i

let expect c i =
  if Char.equal c i.c then ()
  else
    err "expect"
      ("expecting '" ^ Char.escaped c ^ "', got '" ^ Char.escaped i.c ^ "'")
      i

(* <div *)
let start_tag i =
  skip_ws i;
  match i.c with
  | '<' ->
    next i;
    tag i
  | c ->
    err "start_tag"
      ("start tag must start with '<', got '" ^ Char.escaped c ^ "'")
      i

(* /> or > *)
let start_tag_close i =
  skip_ws i;
  match i.c with
  | '/' ->
    next i;
    expect '>' i;
    `Close_slash_gt (* /> *)
  | '>' -> `Close_gt (* > *)
  | c ->
    err "start_tag_close"
      ("'/>' or '>' expected, got '" ^ Char.escaped c ^ "'")
      i

(* </div> *)
let close_tag start_tag i =
  expect '<' i;
  next i;
  expect '/' i;
  next i;
  let close_tag = tag i in
  expect '>' i;
  if String.equal start_tag close_tag then ()
  else
    err "close_tag"
      ("expected closed tag '" ^ start_tag ^ "', got '" ^ close_tag ^ "'")
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

let element i =
  let tag_name = start_tag i in
  skip_ws i;
  let start_tag_close = start_tag_close i in
  let _children =
    if is_void_elem tag_name then []
    else
      match start_tag_close with
      | `Close_slash_gt -> []
      | `Close_gt ->
        next i;
        let children = [] in
        close_tag tag_name i;
        children
  in
  tag_name
