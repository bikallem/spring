type state = { i : string; mutable pos : int }

let accept s n = s.pos <- s.pos + n

let token s =
  let rec aux b =
    match String.get s.i s.pos with
    | ( '0' .. '9'
      | 'a' .. 'z'
      | 'A' .. 'Z'
      | '!'
      | '#'
      | '$'
      | '%'
      | '&'
      | '\''
      | '*'
      | '+'
      | '-'
      | '.'
      | '^'
      | '_'
      | '`'
      | '|'
      | '~' ) as c ->
      accept s 1;
      Buffer.add_char b c;
      aux b
    | _ -> Buffer.contents b
  in
  aux (Buffer.create 5)

(* chomp '=' *)
let eq s =
  match String.get s.i s.pos with
  | '=' -> accept s 1
  | c -> failwith @@ "eq: expected '=', got '" ^ Char.escaped c ^ "'"

let cookie_octet s =
  let rec aux b =
    if s.pos < String.length s.i then
      match String.get s.i s.pos with
      | ( '\x21'
        | '\x23' .. '\x2B'
        | '\x2D' .. '\x3A'
        | '\x3C' .. '\x5B'
        | '\x5D' .. '\x7E' ) as c ->
        accept s 1;
        Buffer.add_char b c;
        aux b
      | _ -> Buffer.contents b
    else Buffer.contents b
  in
  aux (Buffer.create 5)

let cookie_value s =
  match String.get s.i s.pos with
  | '"' -> (
    accept s 1;
    let v = cookie_octet s in
    match String.get s.i s.pos with
    | '"' ->
      accept s 1;
      v
    | c -> failwith "cookie_value: expected '\"', got '" ^ Char.escaped c ^ "'")
  | _ -> cookie_octet s
