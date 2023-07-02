module Definition = struct
  type name = string

  let canonical_name s =
    String.cuts ~sep:"-" s
    |> List.map (fun s -> String.(Ascii.(lowercase s |> capitalize)))
    |> String.concat ~sep:"-"

  type lname = string

  let lname = String.Ascii.lowercase

  let lname_equal = String.equal

  let lname_of_name = String.Ascii.lowercase

  type 'a encode = 'a -> string

  type 'a decode = string -> 'a

  type 'a t =
    { name : lname
    ; decode : 'a decode
    ; encode : 'a encode
    }

  let make name decode encode =
    let name = lname name in
    { name; decode; encode }

  let name (type a) (hdr : a t) = canonical_name hdr.name

  let decode (type a) s (t : a t) = t.decode s

  let encode (type a) (v : a) (t : a t) = t.encode v
end

(* +-- Standard Haeader Definitions --+*)

let content_length =
  Definition.make "content-length" int_of_string string_of_int

let content_type =
  Definition.make "content-type" Content_type.decode Content_type.encode

let content_disposition =
  Definition.make "content-disposition" Content_disposition.decode
    Content_disposition.encode

(* TODO Host header - https://httpwg.org/specs/rfc9110.html#field.host *)
let host = Definition.make "host" Fun.id Fun.id

(** TODO Trailer header - https://httpwg.org/specs/rfc9110.html#field.trailer *)
let trailer = Definition.make "trailer" Fun.id Fun.id

let transfer_encoding =
  Definition.make "transfer-encoding" Transfer_encoding.decode
    Transfer_encoding.encode

let te = Definition.make "te" Te.decode Te.encode

(* TODO Connection header *)
let connection = Definition.make "connection" Fun.id Fun.id

(* TODO User-Agent spec at https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.5 *)
let user_agent = Definition.make "user-agent" Fun.id Fun.id

let date = Definition.make "date" Date.decode Date.encode

let cookie = Definition.make "cookie" Cookie.decode Cookie.encode

let set_cookie =
  Definition.make "set-cookie" Set_cookie.decode Set_cookie.encode

let last_modified = Definition.make "last-modified" Date.decode Date.encode

let if_modified_since =
  Definition.make "if-modified-since" Date.decode Date.encode

let expires = Definition.make "expires" Expires.decode Expires.encode

let etag = Definition.make "etag" Etag.decode Etag.encode

let if_none_match =
  Definition.make "if-none-match" If_none_match.decode If_none_match.encode

let cache_control =
  Definition.make "cache-control" Cache_control.decode Cache_control.encode

(** +-- Header --+ *)

type t = (Definition.lname * string) list

(* +-- Create --+ *)

let empty = []

let singleton ~name ~value = [ (Definition.lname name, value) ]

let is_empty = function
  | [] -> true
  | _ -> false

let of_list t = List.map (fun (k, v) -> (Definition.lname k, v)) t

let to_list = Fun.id

let length t = List.length t

let exists { Definition.name; _ } t =
  let rec aux = function
    | [] -> false
    | [ (name1, _); (name2, _) ] ->
      String.equal name1 name || String.equal name2 name
    | (name', _) :: tl -> if String.equal name' name then true else aux tl
  in
  aux t

let add { Definition.name; encode; _ } v t = (name, encode v) :: t

let add_unless_exists hdr v t = if exists hdr t then t else add hdr v t

let append t1 t2 = t1 @ t2

let find { Definition.name; decode; _ } t =
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

let find_opt { Definition.name; decode; _ } t =
  let decode v = try Some (decode v) with _ -> None in
  let rec aux = function
    | [] -> None
    | (name', v) :: [] -> if String.equal name' name then decode v else None
    | (name1, v1) :: (name2, v2) :: l ->
      if String.equal name1 name then decode v1
      else if String.equal name2 name then decode v2
      else aux l
  in
  aux t

let find_all { Definition.name; decode; _ } t =
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

let remove_first { Definition.name; _ } t =
  let[@tail_mod_cons] rec aux = function
    | [] -> []
    | ((name', _) as x) :: tl ->
      if String.equal name name' then tl else x :: aux tl
  in
  aux t

let remove { Definition.name; _ } t =
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

let replace { Definition.name; encode; _ } v t =
  let[@tail_mod_cons] rec aux seen = function
    | [] -> if not seen then [ (name, encode v) ] else []
    | (name', _) :: tl when String.equal name name' ->
      if seen then aux seen tl else (name', encode v) :: aux true tl
    | (name', v1) :: tl -> (name', v1) :: aux seen tl
  in
  aux false t

let iter f t = List.iter (fun (k, v) -> f k v) t

let filter f t = List.filter (fun (k, v) -> f k v) t

let pp fmt t =
  let sep = Fmt.any ":@ " in
  let name fmt s = Fmt.pf fmt "%s" @@ Definition.canonical_name s in
  let name_value = Fmt.(hvbox ~indent:2 @@ pair ~sep name string) in
  let headers = Fmt.(vbox @@ list ~sep:semi @@ name_value) in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '[' ++ cut ++ headers))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char ']')) fmt t

(* parser *)

open Buf_read
open Buf_read.Syntax

let p_header =
  let+ key = token <* char ':' <* ows
  and+ value = take_while not_cr <* crlf in
  let key = String.Ascii.lowercase key in
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

let write_header_ buf_write k v =
  let f = Eio.Buf_write.string buf_write in
  f @@ Definition.canonical_name k;
  f ": ";
  f v;
  f "\r\n"

let write_header : type a. Eio.Buf_write.t -> a Definition.t -> a -> unit =
 fun buf_write h v ->
  let v = Definition.encode v h in
  let k = Definition.name h in
  write_header_ buf_write k v

let write buf_write t = iter (fun k v -> write_header_ buf_write k v) t
