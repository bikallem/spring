type writable =
  { write_body : Eio.Buf_write.t -> unit
  ; write_headers : Eio.Buf_write.t -> unit
  }

let make_writable ~write_body ~write_headers = { write_body; write_headers }

let none = { write_body = (fun _ -> ()); write_headers = (fun _ -> ()) }

let write_body buf_write body = body.write_body buf_write

let write_headers buf_write body = body.write_headers buf_write

let writable_content content_type content =
  let content_length = String.length content in
  { write_body = (fun w -> Eio.Buf_write.string w content)
  ; write_headers =
      (fun w ->
        Headers.write_header w Headers.content_length content_length;
        Headers.write_header w Headers.content_type content_type)
  }

let writable_form_values assoc_list =
  let content = Uri.encoded_of_query assoc_list in
  let content_type =
    Content_type.make ("application", "x-www-form-urlencoded")
  in
  writable_content content_type content

type readable =
  { headers : Headers.t
  ; buf_read : Eio.Buf_read.t
  }

let make_readable headers buf_read = { headers; buf_read }

let headers r = r.headers

let buf_read r = r.buf_read

let ( let* ) o f = Option.bind o f

let read_content (t : readable) =
  match Headers.(find_opt content_length t.headers) with
  | Some len -> ( try Some (Buf_read.take len t.buf_read) with _ -> None)
  | None -> None

let read_form_values (t : readable) =
  match
    let* content = read_content t in
    let* content_type = Headers.(find_opt content_type t.headers) in
    match (Content_type.media_type content_type :> string * string) with
    | "application", "x-www-form-urlencoded" ->
      Some (Uri.query_of_encoded content)
    | _ -> None
  with
  | Some l -> l
  | None -> []
