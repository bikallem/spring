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

(*
let quoted_string = 
  char '"' *> 
*)

let header =
  let+ key = token <* char ':' <* ows and+ value = take_while not_cr <* crlf in
  (key, value)

let http_headers r =
  let[@tail_mod_cons] rec aux () =
    match peek_char r with
    | Some '\r' ->
        crlf r;
        []
    | _ ->
        let h = header r in
        h :: aux ()
  in
  aux ()
