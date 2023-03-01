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

    method next_char =
      self#next;
      self#c

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
    match i#next_char with
    | c when is_alpha_num c ->
      i#add;
      aux ()
    | '_' | '\'' | '.' ->
      i#add;
      aux ()
    | _ ->
      let tag = Buffer.contents i#buf in
      clear i;
      tag
  in
  match i#next_char with
  | c when is_alpha c || c = '_' ->
    i#add;
    aux ()
  | _ ->
    err "start_tag" "tag name must start with an alphabet or '_' character" i

let expect c (i : #input) =
  if Char.equal c i#c then i#next
  else
    err "expect"
      ("expecting '" ^ Char.escaped c ^ "', got '" ^ Char.escaped i#c ^ "'")
      i

let element (i : #input) =
  i#next;
  skip_ws i;
  match i#c with
  | '<' ->
    let name =
      let nm = tag i in
      (* attributes *)
      skip_ws i;
      expect '>' i;
      nm
    in

    name
  | _ -> err "start_tag" "start tag must start with '<'" i
