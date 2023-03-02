let nul = '\000'

class virtual input =
  object (self)
    val mutable line = 1

    val mutable col = 0

    val mutable c = nul

    val buf = Buffer.create 10

    method line = line

    method col = col

    method c = c

    method buf = buf

    method add = Buffer.add_char buf c

    method next =
      let c' = self#char in
      match c' with
      | '\n' ->
        col <- 1;
        line <- line + 1;
        c <- c'
      | _ ->
        col <- col + 1;
        c <- c'

    method virtual char : char
  end

let string_input s =
  let len = String.length s in
  let pos = ref (-1) in
  object
    inherit input

    method char =
      incr pos;
      if !pos = len then (
        c <- nul;
        raise End_of_file)
      else String.get s !pos
  end

let channel_input in_channel =
  object
    inherit input

    method char = input_char in_channel
  end

let err lbl msg (i : #input) =
  failwith
    (lbl ^ "(" ^ string_of_int i#line ^ "," ^ string_of_int i#col ^ ") : " ^ msg)

let clear (i : #input) = Buffer.clear i#buf

let is_alpha = function
  | 'a' .. 'z' | 'A' .. 'Z' -> true
  | _ -> false

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false

let is_alpha_num = function
  | c -> is_alpha c || is_digit c

let rec skip_ws (i : #input) =
  match i#c with
  | '\t' | ' ' | '\n' | '\r' ->
    i#next;
    skip_ws i
  | _ -> ()

let tag i =
  let rec aux () =
    match i#c with
    | c when is_alpha_num c ->
      i#add;
      i#next;
      aux ()
    | '_' | '\'' | '.' ->
      i#add;
      i#next;
      aux ()
    | _ ->
      let tag = Buffer.contents i#buf in
      clear i;
      tag
  in
  match i#c with
  | c when is_alpha c || c = '_' ->
    i#add;
    i#next;
    aux ()
  | _ ->
    err "start_tag"
      ("tag name must start with an alphabet or '_' character, got '"
     ^ Char.escaped i#c ^ "'")
      i

let expect c (i : #input) =
  if Char.equal c i#c then ()
  else
    err "expect"
      ("expecting '" ^ Char.escaped c ^ "', got '" ^ Char.escaped i#c ^ "'")
      i

(* <div *)
let start_tag (i : #input) =
  skip_ws i;
  match i#c with
  | '<' ->
    i#next;
    tag i
  | c ->
    err "start_tag"
      ("start tag must start with '<', got '" ^ Char.escaped c ^ "'")
      i

(* /> or > *)
let start_tag_close i =
  skip_ws i;
  match i#c with
  | '/' ->
    i#next;
    expect '>' i;
    i#next;
    `Close_elem
  | '>' ->
    i#next;
    `Close_start_tag
  | c ->
    err "start_tag_close"
      ("'/>' or '>' expected, got '" ^ Char.escaped c ^ "'")
      i

(* </div> *)
let close_tag start_tag i =
  expect '<' i;
  i#next;
  expect '/' i;
  i#next;
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

let element (i : #input) =
  let tag_name = start_tag i in
  skip_ws i;
  let start_tag_close = start_tag_close i in
  let _children =
    if is_void_elem tag_name then []
    else
      match start_tag_close with
      | `Close_elem -> []
      | `Close_start_tag -> []
  in
  close_tag tag_name i;
  tag_name

let root (i : #input) =
  i#next;
  element i
