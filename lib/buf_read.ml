include Eio.Buf_read

let take_while1_err () = failwith "take_while1"

let take_while1 ?(on_error = take_while1_err) p r =
  match take_while p r with
  | "" -> on_error ()
  | x -> x

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

let quoted_text =
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
      let c = quoted_text r in
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
  take_while (function
    | '\x21'
    | '\x23' .. '\x2B'
    | '\x2D' .. '\x3A'
    | '\x3C' .. '\x5B'
    | '\x5D' .. '\x7E' -> true
    | _ -> false)

let cookie_value : string parser =
  let* c = peek_char in
  match c with
  | Some '"' ->
    let+ v = char '"' *> cookie_octet <* char '"' in
    "\"" ^ v ^ "\""
  | Some _ | None -> cookie_octet

(* +-- Cookie Pair --+ *)

(* https://datatracker.ietf.org/doc/html/rfc6265#section-4.1 *)
let cookie_pair : (string * string) parser =
  ows *> token <* ows <* char '=' *> ows <*> cookie_value

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

let digit =
  take_while1 (function
    | '0' .. '9' -> true
    | _ -> false)

let delta_seconds t = digit t |> int_of_string

let validate param_name p v =
  match parse_string p v with
  | Ok v -> v
  | Error (`Msg err) -> Fmt.invalid_arg "[%s] is invalid. %s" param_name err

(** +-- Generic URI

    https://datatracker.ietf.org/doc/html/rfc3986#appendix-A --+ *)

let hex_dig t : char =
  match any_char t with
  | ('0' .. '9' | 'A' .. 'F') as c -> c
  | c -> Fmt.failwith "expected HEXDIG but got '%c'" c

let segment t : string =
  let buf = Buffer.create 10 in
  let rec loop () =
    match peek_char t with
    | Some
        (( 'a' .. 'z'
         | 'A' .. 'Z'
         | '0' .. '9'
         | '-' | '.' | '_' | '~' (* unreserved *)
         | '!'
         | '$'
         | '&'
         | '\''
         | '('
         | ')'
         | '*'
         | '+'
         | ','
         | ';'
         | '=' (* sub-delims *)
         | ':' | '@' ) as c) ->
      char c t;
      Buffer.add_char buf c;
      loop ()
    | Some ('%' as c) ->
      char c t;
      Buffer.add_char buf c;
      Buffer.add_char buf @@ hex_dig t;
      Buffer.add_char buf @@ hex_dig t;
      loop ()
    | _ -> Buffer.contents buf
  in
  loop ()
