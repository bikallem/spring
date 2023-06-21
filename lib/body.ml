type writable =
  { write_body : Eio.Buf_write.t -> unit
  ; write_headers : Eio.Buf_write.t -> unit
  }

let make_writable ~write_body ~write_headers = { write_body; write_headers }
let none = { write_body = (fun _ -> ()); write_headers = (fun _ -> ()) }

let content_writer content_type content =
  let content_length = String.length content in
  { write_body = (fun w -> Eio.Buf_write.string w content)
  ; write_headers =
      (fun w ->
        Header.write_header w Header.content_length content_length;
        Header.write_header w Header.content_type content_type)
  }

let form_values_writer assoc_list =
  let content = Uri.encoded_of_query assoc_list in
  let content_type =
    Content_type.make ("application", "x-www-form-urlencoded")
  in
  content_writer content_type content

class virtual readable =
  object
    method virtual headers : Header.t
    method virtual buf_read : Eio.Buf_read.t
  end

type readable' = { headers : Header.t; buf_read : Eio.Buf_read.t }

let make_readable headers buf_read = { headers; buf_read }
let ( let* ) o f = Option.bind o f

let read_content (t : #readable) =
  match Header.(find_opt t#headers content_length) with
  | Some len -> ( try Some (Buf_read.take len t#buf_read) with _ -> None)
  | None -> None

let read_content' (t : readable') =
  match Header.(find_opt t.headers content_length) with
  | Some len -> ( try Some (Buf_read.take len t.buf_read) with _ -> None)
  | None -> None

let read_form_values (t : #readable) =
  match
    let* content = read_content t in
    let* content_type = Header.(find_opt t#headers content_type) in
    match (Content_type.media_type content_type :> string * string) with
    | "application", "x-www-form-urlencoded" ->
      Some (Uri.query_of_encoded content)
    | _ -> None
  with
  | Some l -> l
  | None -> []

let read_form_values' (t : readable') =
  match
    let* content = read_content' t in
    let* content_type = Header.(find_opt t.headers content_type) in
    match (Content_type.media_type content_type :> string * string) with
    | "application", "x-www-form-urlencoded" ->
      Some (Uri.query_of_encoded content)
    | _ -> None
  with
  | Some l -> l
  | None -> []
