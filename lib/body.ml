class virtual writable =
  object
    method virtual write_body : Eio.Buf_write.t -> unit

    method virtual write_header
        : < f : 'a. 'a Header.header -> 'a -> unit > -> unit
  end

type write_header = { f : 'a. 'a Header.header -> 'a -> unit }

type writable' =
  { write_body : Eio.Buf_write.t -> unit; write_headers : write_header -> unit }

class none =
  object
    inherit writable
    method write_body _ = ()
    method write_header _ = ()
  end

let none = new none
let none' = { write_body = (fun _ -> ()); write_headers = (fun _ -> ()) }

let content_writer content_type content =
  let content_length = String.length content in
  object
    method write_body w = Eio.Buf_write.string w content

    method write_header (f : < f : 'a. 'a Header.header -> 'a -> unit >) =
      f#f Header.content_length content_length;
      f#f Header.content_type content_type
  end

let content_writer' content_type content =
  let content_length = String.length content in
  { write_body = (fun w -> Eio.Buf_write.string w content)
  ; write_headers =
      (fun wh ->
        wh.f Header.content_length content_length;
        wh.f Header.content_type content_type)
  }

let form_values_writer assoc_list =
  let content = Uri.encoded_of_query assoc_list in
  let content_type =
    Content_type.make ("application", "x-www-form-urlencoded")
  in
  content_writer content_type content

let form_values_writer' assoc_list =
  let content = Uri.encoded_of_query assoc_list in
  let content_type =
    Content_type.make ("application", "x-www-form-urlencoded")
  in
  content_writer' content_type content

class virtual readable =
  object
    method virtual headers : Header.t
    method virtual buf_read : Eio.Buf_read.t
  end

let ( let* ) o f = Option.bind o f

let read_content (t : #readable) =
  match Header.(find_opt t#headers content_length) with
  | Some len -> ( try Some (Buf_read.take len t#buf_read) with _ -> None)
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
