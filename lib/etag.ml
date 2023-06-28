type etag_chars = string

type t =
  | Weak of etag_chars
  | Strong of etag_chars

let etag_chars buf_read =
  Buf_read.take_while
    (function
      | '\x21' (* ! *)
      | '\x23' .. '\x7E' (* VCHAR except DQUOTE *)
      | '\x80' .. '\xFF' (* obs-text *) -> true
      | _ -> false)
    buf_read

let make ?(weak = false) s =
  let buf_read = Buf_read.of_string s in
  let s = etag_chars buf_read in
  if Buf_read.at_end_of_input buf_read then
    match weak with
    | true -> Weak s
    | false -> Strong s
  else invalid_arg @@ "[s] contains invalid ETag value"

let opaque_tag buf_read =
  let open Buf_read.Syntax in
  let tag = (Buf_read.char '"' *> etag_chars <* Buf_read.char '"') buf_read in
  if Buf_read.at_end_of_input buf_read then tag
  else invalid_arg "[v] contains invalid ETag value"

let parse buf_read =
  match Buf_read.peek_char buf_read with
  | Some 'W' ->
    Buf_read.string "W/" buf_read;
    let etag_chars = opaque_tag buf_read in
    Weak etag_chars
  | Some '"' -> Strong (opaque_tag buf_read)
  | Some _ | None -> invalid_arg "[v] contains invalid ETag value"

let decode v =
  let buf_read = Buf_read.of_string v in
  parse buf_read

let chars = function
  | Weak v -> v
  | Strong v -> v

let is_weak = function
  | Weak _ -> true
  | Strong _ -> false

let is_strong = function
  | Weak _ -> false
  | Strong _ -> true

type equal = t -> t -> bool

let strong_equal a b =
  match (a, b) with
  | Weak _, _ -> false
  | _, Weak _ -> false
  | Strong a, Strong b -> String.equal a b

let weak_equal a b =
  match (a, b) with
  | Weak a, Weak b -> String.equal a b
  | Weak a, Strong b -> String.equal a b
  | Strong a, Weak b -> String.equal a b
  | Strong a, Strong b -> String.equal a b

let encode = function
  | Weak etag_chars -> "W/\"" ^ etag_chars ^ "\""
  | Strong etag_chars -> "\"" ^ etag_chars ^ "\""

let compare a b =
  match (a, b) with
  | Weak a, Weak b -> String.compare a b
  | Weak _, Strong _ -> -1
  | Strong _, Weak _ -> 1
  | Strong a, Strong b -> String.compare a b
