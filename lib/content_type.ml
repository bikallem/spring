module M = Map.Make (String)

type t = { type_ : string; sub_type : string; parameters : string M.t }
type media_type = string * string

open Buf_read.Syntax
open Buf_read

let p r =
  let type_ = token r in
  let sub_type = (char '/' *> token) r in
  let parameters = parameters r in
  let parameters = M.of_seq @@ List.to_seq parameters in
  { type_; sub_type; parameters }

let make ?(params = []) (type_, sub_type) =
  let parameters = M.of_seq @@ List.to_seq params in
  { type_; sub_type; parameters }

let decode v = p (of_string v)

let encode t =
  let buf = Buffer.create 10 in
  Buffer.add_string buf t.type_;
  Buffer.add_string buf "/";
  Buffer.add_string buf t.sub_type;
  M.iter
    (fun name value ->
      Buffer.add_string buf "; ";
      Buffer.add_string buf name;
      Buffer.add_string buf "=";
      Buffer.add_string buf value)
    t.parameters;
  Buffer.contents buf

let media_type t = (t.type_, t.sub_type)
let find_param t name = M.find_opt (String.lowercase_ascii name) t.parameters
let charset t = M.find_opt "charset" t.parameters
