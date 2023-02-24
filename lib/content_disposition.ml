module M = Map.Make (String)

type t = { disposition : string; parameters : string M.t }
type disposition = string

open Buf_read
(* open Buf_read.Syntax*)

let make ?(params = []) disposition =
  let parameters = M.of_seq @@ List.to_seq params in
  { disposition; parameters }

let decode v =
  let r = Buf_read.of_string v in
  let disposition = token r in
  let parameters = parameters r |> List.to_seq |> M.of_seq in
  { disposition; parameters }

let encode t =
  let buf = Buffer.create 10 in
  Buffer.add_string buf t.disposition;
  M.iter
    (fun name value ->
      Buffer.add_string buf "; ";
      Buffer.add_string buf name;
      Buffer.add_string buf "=";
      Buffer.add_string buf value)
    t.parameters;
  Buffer.contents buf

let disposition t = t.disposition
let find_param t param = M.find_opt param t.parameters
