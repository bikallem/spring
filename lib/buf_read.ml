include Eio.Buf_read

let token =
  take_while1 (function
    | '0' .. '9'
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
    | '~' -> true
    | _ -> false)

let ows =
  skip_while (function
    | ' ' | '\t' -> true
    | _ -> false)

let crlf = string "\r\n"

let not_cr = function
  | '\r' -> false
  | _ -> true

let space = char '\x20'

open Syntax

let quoted_pair =
  char '\\'
  *> let+ c = any_char in
     match c with
     | '\x09' | ' ' | '\x21' .. '\x7E' | '\x80' .. '\xFF' -> c
     | _ -> failwith ("Invalid quoted pair '" ^ Char.escaped c ^ "'")

let qd_text =
  let+ c = any_char in
  match c with
  | '\t' | ' ' | '\x21' | '\x23' .. '\x5B' | '\x5D' .. '\x7E' | '\x80' .. '\xFF'
    -> c
  | _ -> failwith ("Invalid qd_text '" ^ Char.escaped c ^ "'")

let quoted_string =
  let rec aux r =
    let c = peek_char r in
    match c with
    | Some '"' -> []
    | Some '\\' ->
      let c = quoted_pair r in
      c :: aux r
    | Some _ ->
      let c = qd_text r in
      c :: aux r
    | None ->
      failwith "Invalid quoted_string. Looking for '\"', '\\' or qd_text value"
  in
  (char '"'
  *> let+ str = aux in
     Stdlib.String.of_seq @@ List.to_seq str)
  <* char '"'

let parameter =
  let* name = char ';' *> ows *> token in
  let name = String.Ascii.lowercase name in
  let+ value =
    char '='
    *> let* c = peek_char in
       match c with
       | Some '"' -> quoted_string
       | Some _ -> token
       | None -> failwith "parameter: expecting '\"' or token chars buf got EOF"
  in
  (name, value)

let rec parameters r =
  let c = (ows *> peek_char) r in
  match c with
  | Some ';' ->
    let param = parameter r in
    param :: parameters r
  | Some _ | None -> []

let cookie_octet =
  let is_octet = function
    | '\x21'
    | '\x23' .. '\x2B'
    | '\x2D' .. '\x3A'
    | '\x3C' .. '\x5B'
    | '\x5D' .. '\x7E' -> true
    | _ -> false
  in
  take_while is_octet

let cookie_value : string parser =
  let* c = peek_char in
  match c with
  | Some '"' -> char '"' *> cookie_octet <* char '"'
  | Some _ | None -> cookie_octet

let cookie_pair : (string * string) parser = token <* char '=' <*> cookie_value

(* +-- #element - https://www.rfc-editor.org/rfc/rfc9110#name-lists-rule-abnf-extension --+ *)

let rec next_element p t =
  match (ows *> peek_char) t with
  | Some ',' -> (
    char ',' t;
    ows t;
    match peek_char t with
    | Some ',' -> next_element p t
    | Some _ ->
      let x = p t in
      x :: next_element p t
    | None -> [])
  | Some c -> failwith @@ Printf.sprintf "[list1] expected ',' but got %c" c
  | None -> []

let list1 (p : 'a parser) t =
  (* TODO why doesn't this code work (p t :: next_element p t)? but the one below
     works. Is this mis compilation ? *)
  let x = p t in
  let l = x :: next_element p t in
  match l with
  | [] -> failwith "[list1] empty elements, requires at least one element"
  | l -> l
