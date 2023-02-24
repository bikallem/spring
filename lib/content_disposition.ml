module M = Map.Make (String)

type t = { disposition : string; parameters : string M.t }

open Buf_read
(* open Buf_read.Syntax*)

let decode v =
  let r = Buf_read.of_string v in
  let disposition = token r in
  let parameters = parameters r |> List.to_seq |> M.of_seq in
  { disposition; parameters }

let disposition t = t.disposition
let find_param t param = M.find_opt param t.parameters
