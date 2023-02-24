type name = string
type lname = string

let canonical_name s =
  String.split_on_char '-' s
  |> List.map (fun s -> String.(lowercase_ascii s |> capitalize_ascii))
  |> String.concat "-"

let lname = String.lowercase_ascii
let lname_equal = String.equal

type 'a encode = 'a -> string
type 'a decode = string -> 'a
type t = (lname * string) list
type 'a header = { name : lname; decode : 'a decode; encode : 'a encode }

let header decode encode name = { name = lname name; decode; encode }

module H = struct
  let content_length =
    { name = "content-length"; decode = int_of_string; encode = string_of_int }

  let content_type =
    {
      name = "content-type";
      decode = Content_type.decode;
      encode = Content_type.encode;
    }

  let host = { name = "host"; decode = Fun.id; encode = Fun.id }
  let trailer = { name = "trailer"; decode = Fun.id; encode = Fun.id }

  let transfer_encoding =
    {
      name = "transfer-encoding";
      decode = Transfer_encoding_hdr.decode;
      encode = Transfer_encoding_hdr.encode;
    }

  let te = { name = "te"; decode = Te_hdr.decode; encode = Te_hdr.encode }
  let connection = { name = "connection"; decode = Fun.id; encode = Fun.id }
  let user_agent = { name = "user-agent"; decode = Fun.id; encode = Fun.id }
  let date = { name = "date"; decode = Fun.id; encode = Fun.id }
end

include H

let empty = []
let singleton ~name ~value = [ (lname name, value) ]
let is_empty = function [] -> true | _ -> false
let of_list t = List.map (fun (k, v) -> (lname k, v)) t
let to_list = Fun.id
let to_canonical_list t = List.map (fun (k, v) -> (canonical_name k, v)) t
let length t = List.length t

let exists t { name; _ } =
  let rec aux = function
    | [] -> false
    | [ (name1, _); (name2, _) ] ->
        String.equal name1 name || String.equal name2 name
    | (name', _) :: tl -> if String.equal name' name then true else aux tl
  in
  aux t

let add t { name; encode; _ } v = (name, encode v) :: t
let add_unless_exists t hdr v = if exists t hdr then t else add t hdr v
let append t1 t2 = t1 @ t2
let append_list (t : t) l = t @ l

let find t { name; decode; _ } =
  let rec aux = function
    | [] -> raise_notrace Not_found
    | (name', v) :: [] ->
        if String.equal name' name then decode v else raise_notrace Not_found
    | (name1, v1) :: (name2, v2) :: l ->
        if String.equal name1 name then decode v1
        else if String.equal name2 name then decode v2
        else aux l
  in
  aux t

let find_opt t hdr = try Some (find t hdr) with Not_found -> None

let find_all t { name; decode; _ } =
  let[@tail_mod_cons] rec aux = function
    | [] -> []
    | [ (name', v) ] -> if String.equal name name' then [ decode v ] else []
    | [ (name1, v1); (name2, v2) ] -> (
        match (String.equal name name1, String.equal name name2) with
        | true, true -> [ decode v1; decode v2 ]
        | true, false -> [ decode v1 ]
        | false, true -> [ decode v2 ]
        | false, false -> [])
    | (name1, v1) :: (name2, v2) :: tl -> (
        match (String.equal name name1, String.equal name name2) with
        | true, true -> decode v1 :: decode v2 :: aux tl
        | true, false -> decode v1 :: aux tl
        | false, true -> decode v2 :: aux tl
        | false, false -> aux tl)
  in
  aux t

let remove t { name; _ } =
  let[@tail_mod_cons] rec aux = function
    | [] -> []
    | [ (name', _) ] as l -> if String.equal name name' then [] else l
    | [ (name1, v1); (name2, v2) ] -> (
        match (String.equal name name1, String.equal name name2) with
        | true, true -> []
        | true, false -> [ (name2, v2) ]
        | false, true -> [ (name1, v1) ]
        | false, false -> [ (name1, v1); (name2, v2) ])
    | (name1, v1) :: (name2, v2) :: tl -> (
        match (String.equal name name1, String.equal name name2) with
        | true, true -> aux tl
        | true, false -> (name2, v2) :: aux tl
        | false, true -> (name1, v1) :: aux tl
        | false, false -> (name1, v1) :: (name2, v2) :: aux tl)
  in
  aux t

let replace t { name; encode; _ } v =
  let[@tail_mod_cons] rec aux seen = function
    | [] -> []
    | (name', _) :: tl when String.equal name name' ->
        if seen then aux seen tl else (name', encode v) :: aux true tl
    | (name', v1) :: tl -> (name', v1) :: aux seen tl
  in
  aux false t

let clean_dup t = t
let iter f t = List.iter (fun (k, v) -> f k v) t
let filter f t = List.filter (fun (k, v) -> f k v) t

open Easy_format

let field lbl v =
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let easy_fmt t =
  let p =
    {
      list with
      stick_to_label = false;
      align_closing = true;
      space_after_separator = true;
      wrap_body = `Force_breaks;
    }
  in
  let t = to_list t |> List.map (fun (k, v) -> field k v) in
  List (("{", ";", "}", p), t)

let pp fmt t = Easy_format.Pretty.to_formatter fmt (easy_fmt t)

(* parser *)

open Buf_read
open Buf_read.Syntax

let p_header =
  let+ key = token <* char ':' <* ows and+ value = take_while not_cr <* crlf in
  let key = String.lowercase_ascii key in
  (key, value)

let parse r =
  let[@tail_mod_cons] rec aux () =
    match peek_char r with
    | Some '\r' ->
        crlf r;
        []
    | _ ->
        let h = p_header r in
        h :: aux ()
  in
  aux ()
