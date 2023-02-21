type name = string
type lname = string

let canonical_name s =
  String.split_on_char '-' s
  |> List.map (fun s -> String.(lowercase_ascii s |> capitalize_ascii))
  |> String.concat "-"

let lname = String.lowercase_ascii

type 'a encode = 'a -> string
type 'a decode = string -> 'a
type t = (lname * string) list
type 'a header = { name : lname; decode : 'a decode; encode : 'a encode }

let header decode encode name = { name = lname name; decode; encode }

let content_length =
  { name = "content-length"; decode = int_of_string; encode = string_of_int }

let content_type = { name = "content-type"; decode = Fun.id; encode = Fun.id }
let host = { name = "host"; decode = Fun.id; encode = Fun.id }

(* Transfer-Encoding header.
   TODO bikal ensure that elements maintain the order on encoding/decoding. `chunked must appear last
*)
let transfer_encoding =
  let decode v =
    String.split_on_char ',' v
    |> List.map String.trim
    |> List.filter (fun s -> s <> "")
    |> List.map (fun te ->
           match te with
           | "chunked" -> `chunked
           | "compress" -> `compress
           | "deflate" -> `deflate
           | "gzip" -> `gzip
           | v -> failwith @@ "Invalid 'Transfer-Encoding' value " ^ v)
  in
  let encode v =
    List.map
      (function
        | `chunked -> "chunked"
        | `compress -> "compress"
        | `deflate -> "deflate"
        | `gzip -> "gzip")
      v
    |> String.concat ", "
  in
  { name = "transfer-encoding"; decode; encode }

let empty = []
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
