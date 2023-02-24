module M = Map.Make (String)

type t = { type_ : string; sub_type : string; parameters : string M.t }

open Buf_read.Syntax
open Buf_read

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

let p r =
  let rec aux () =
    let c = (ows *> peek_char) r in
    match c with
    | Some ';' ->
        let param = parameter r in
        param :: aux ()
    | Some _ | None -> []
  in
  let type_ = token r in
  let sub_type = (char '/' *> token) r in
  let parameters = aux () in
  let parameters = M.of_seq @@ List.to_seq parameters in
  { type_; sub_type; parameters }

let decode v = p (of_string v)
let media_type t = (t.type_, t.sub_type)
let find_param t name = M.find_opt (String.lowercase_ascii name) t.parameters
let charset t = M.find_opt "charset" t.parameters
