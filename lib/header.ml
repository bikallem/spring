type name = string
type lname = string

let canonical_name s =
  String.cuts ~sep:"-" s
  |> List.map (fun s -> String.(Ascii.(lowercase s |> capitalize)))
  |> String.concat ~sep:"-"

let lname = String.Ascii.lowercase
let lname_equal = String.equal
let lname_of_name = String.Ascii.lowercase

type 'a encode = 'a -> string
type 'a decode = string -> 'a
type t = (lname * string) list
type 'a header = { name : lname; decode : 'a decode; encode : 'a encode }

let header decode encode name = { name = lname name; decode; encode }
let name (type a) (hdr : a header) = canonical_name hdr.name
let encode (type a) (hdr : a header) (v : a) = hdr.encode v

let content_length =
  { name = "content-length"; decode = int_of_string; encode = string_of_int }

let content_type =
  { name = "content-type"
  ; decode = Content_type.decode
  ; encode = Content_type.encode
  }

let content_disposition =
  { name = "content-disposition"
  ; decode = Content_disposition.decode
  ; encode = Content_disposition.encode
  }

(* TODO Host header - https://httpwg.org/specs/rfc9110.html#field.host *)
let host = { name = "host"; decode = Fun.id; encode = Fun.id }

(** TODO Trailer header - https://httpwg.org/specs/rfc9110.html#field.trailer *)
let trailer = { name = "trailer"; decode = Fun.id; encode = Fun.id }

let transfer_encoding =
  { name = "transfer-encoding"
  ; decode = Transfer_encoding.decode
  ; encode = Transfer_encoding.encode
  }

let te = { name = "te"; decode = Te.decode; encode = Te.encode }

(* TODO Connection header *)
let connection = { name = "connection"; decode = Fun.id; encode = Fun.id }

(* TODO User-Agent spec at https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.5 *)
let user_agent = { name = "user-agent"; decode = Fun.id; encode = Fun.id }
let date = { name = "date"; decode = Date.decode; encode = Date.encode }
let cookie = { name = "cookie"; decode = Cookie.decode; encode = Cookie.encode }

let set_cookie =
  { name = "set-cookie"
  ; decode = Set_cookie.decode
  ; encode = Set_cookie.encode
  }

let empty = []
let singleton ~name ~value = [ (lname name, value) ]

let is_empty = function
  | [] -> true
  | _ -> false

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

let find_opt t { name; decode; _ } =
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

let remove_first t { name; _ } =
  let[@tail_mod_cons] rec aux = function
    | [] -> []
    | ((name', _) as x) :: tl ->
      if String.equal name name' then tl else x :: aux tl
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
    | [] -> if not seen then [ (name, encode v) ] else []
    | (name', _) :: tl when String.equal name name' ->
      if seen then aux seen tl else (name', encode v) :: aux true tl
    | (name', v1) :: tl -> (name', v1) :: aux seen tl
  in
  aux false t

let iter f t = List.iter (fun (k, v) -> f k v) t
let filter f t = List.filter (fun (k, v) -> f k v) t

open Easy_format

let field lbl v =
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let easy_fmt t =
  let p =
    { list with
      stick_to_label = false
    ; align_closing = true
    ; space_after_separator = true
    ; wrap_body = `Force_breaks
    }
  in
  let t = to_list t |> List.map (fun (k, v) -> field (canonical_name k) v) in
  List (("{", ";", "}", p), t)

let pp fmt t = Easy_format.Pretty.to_formatter fmt (easy_fmt t)

(* parser *)

open Buf_read
open Buf_read.Syntax

let p_header =
  let+ key = token <* char ':' <* ows and+ value = take_while not_cr <* crlf in
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

let write_header f k v =
  f k;
  f ": ";
  f v;
  f "\r\n"

let write_header' : type a. Eio.Buf_write.t -> a header -> a -> unit =
 fun bw h v ->
  let v = encode h v in
  let nm = name h in
  Eio.Buf_write.string bw nm;
  Eio.Buf_write.string bw ": ";
  Eio.Buf_write.string bw v;
  Eio.Buf_write.string bw "\r\n"

let write t f = iter (fun k v -> write_header f (canonical_name k) v) t
