type t =
  | Any
  | Entity_tags of Etag.t list

let any = Any

let make = function
  | [] -> invalid_arg "[entity_tags] is empty"
  | etags -> Entity_tags etags

let entity_tags = function
  | Any -> None
  | Entity_tags etags -> Some etags

let is_any = function
  | Any -> true
  | Entity_tags (_ : Etag.t list) -> false

let contains_entity_tag f = function
  | Any -> true
  | Entity_tags etags -> List.exists f etags

let decode s =
  let buf_read = Buf_read.of_string s in
  let parse_etag = Etag.parse ~consume:`Prefix in
  let t =
    match Buf_read.peek_char buf_read with
    | Some '*' ->
      Buf_read.char '*' buf_read;
      Any
    | Some (_ : char) ->
      let etags = Buf_read.list1 parse_etag buf_read in
      Entity_tags etags
    | None -> invalid_arg "[s] contains invalid [If-None-Match] value"
  in
  if Buf_read.at_end_of_input buf_read then t
  else invalid_arg "[s] contains invalid [If-None-Match] value"

let encode = function
  | Any -> "*"
  | Entity_tags etags ->
    let buf = Buffer.create 10 in
    let rec write_etag = function
      | [] -> Buffer.contents buf
      | etag :: [] ->
        Buffer.add_string buf (Etag.encode etag);
        Buffer.contents buf
      | etag :: etags ->
        Buffer.add_string buf (Etag.encode etag);
        Buffer.add_string buf ", ";
        write_etag etags
    in
    write_etag etags

let pp fmt t = Format.fprintf fmt "%s" @@ encode t
