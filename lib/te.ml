type directive = string
type q = string

module M = Set.Make (struct
  type t = directive * q option

  let compare ((d1, _) : t) ((d2, _) : t) =
    match (d1, d2) with
    | "trailers", "trailers" -> 0
    | "trailers", _ -> -1
    | _, "trailers" -> 1
    | _, _ -> Stdlib.compare d1 d2
end)

let directive = Fun.id
let trailers = "trailers"
let compress = "compress"
let deflate = "deflate"
let gzip = "gzip"

type t = M.t

let singleton ?q d = M.singleton (d, q)
let exists t d = M.mem (d, None) t
let add ?q t d = M.add (d, q) t

let get_q t d : q option =
  match M.find_opt (d, None) t with
  | Some (_, q) -> q
  | None -> None

let remove t d = M.remove (d, None) t
let iter f t = M.iter (fun (d, q) -> f d q) t

let encode t =
  let q_to_str = function
    | Some q -> ";q=" ^ q
    | None -> ""
  in
  M.to_seq t
  |> List.of_seq
  |> List.map (fun (d, q) -> d ^ q_to_str q)
  |> String.concat ~sep:", "

open Buf_read.Syntax
open Buf_read

let is_q_value = function
  | '0' .. '9' -> true
  | '.' -> true
  | _ -> false

let p_directive =
  let parse_qval () =
    let* ch = peek_char in
    match ch with
    | Some ';' ->
      let+ v = char ';' *> ows *> string "q=" *> take_while1 is_q_value in
      Some v
    | _ -> return None
  in
  let* directive = token <* ows in
  let+ q =
    match directive with
    | "trailers" -> return None
    | _ -> parse_qval ()
  in
  (directive, q)

let decode v =
  let r = Buf_read.of_string v in
  let d = p_directive r in
  let rec aux () =
    match peek_char r with
    | Some ',' ->
      let d = (char ',' *> ows *> p_directive) r in
      d :: aux ()
    | _ -> []
  in
  M.of_list (d :: aux ())
