type directive = [ `trailers | `compress of q | `deflate of q | `gzip of q ]
and q = string option

module M = Set.Make (struct
  type t = directive

  let compare (a : directive) (b : directive) = Stdlib.compare a b
end)

type t = M.t

let exists = M.mem
let add = M.add
let remove = M.remove
let iter = M.iter

let encode t =
  let q_to_str = function Some q -> ";q=" ^ q | None -> "" in
  M.to_seq t
  |> List.of_seq
  |> List.map (function
       | `trailers -> "trailers"
       | `compress q -> "compress" ^ q_to_str q
       | `deflate q -> "deflate" ^ q_to_str q
       | `gzip q -> "gzip" ^ q_to_str q)
  |> String.concat ", "

open Buf_read.Syntax
open Buf_read

let is_q_value = function '0' .. '9' -> true | '.' -> true | _ -> false

let directive =
  let parse_qval () =
    let* ch = peek_char in
    match ch with
    | Some ';' ->
        let+ v = char ';' *> ows *> string "q=" *> take_while1 is_q_value in
        Some v
    | _ -> return None
  in
  let* directive = token <* ows in
  match directive with
  | "trailers" -> return `trailers
  | "compress" ->
      let+ q = parse_qval () in
      `compress q
  | "deflate" ->
      let+ q = parse_qval () in
      `deflate q
  | "gzip" ->
      let+ q = parse_qval () in
      `gzip q
  | _ -> failwith ("Unknown directive '" ^ directive ^ "' in TE header")

let decode v =
  let r = Buf_read.of_string v in
  let d = directive r in
  let rec aux () =
    match peek_char r with
    | Some ',' ->
        let d = (char ',' *> ows *> directive) r in
        d :: aux ()
    | _ -> []
  in
  M.of_list (d :: aux ())
