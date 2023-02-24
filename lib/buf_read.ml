include Eio.Buf_read

let take_while1 p r =
  match take_while p r with "" -> raise End_of_file | x -> x

let token =
  take_while1 (function
    | '0' .. '9'
    | 'a' .. 'z'
    | 'A' .. 'Z'
    | '!' | '#' | '$' | '%' | '&' | '\'' | '*' | '+' | '-' | '.' | '^' | '_'
    | '`' | '|' | '~' ->
        true
    | _ -> false)

let ows = skip_while (function ' ' | '\t' -> true | _ -> false)
let crlf = string "\r\n"
let not_cr = function '\r' -> false | _ -> true
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
    ->
      c
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
        failwith
          "Invalid quoted_string. Looking for '\"', '\\' or qd_text value"
  in
  (char '"'
  *> let+ str = aux in
     String.of_seq @@ List.to_seq str)
  <* char '"'

let parameter =
  let* name = char ';' *> ows *> token in
  let name = String.lowercase_ascii name in
  let+ value =
    char '='
    *> let* c = peek_char in
       match c with
       | Some '"' -> quoted_string
       | Some _ -> token
       | None -> failwith "parameter: expecting '\"' or token chars buf got EOF"
  in
  (name, value)
