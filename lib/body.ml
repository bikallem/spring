class virtual writable =
  object
    method virtual write_body : Eio.Buf_write.t -> unit

    method virtual write_header : (name:string -> value:string -> unit) -> unit
  end

class none =
  object
    inherit writable

    method write_body _ = ()

    method write_header _ = ()
  end

let none = new none

let content_writer ~content ~content_type =
  let content_length = String.length content in
  object
    method write_body w = Buf_write.string w content

    method write_header f =
      f ~name:"Content-Length" ~value:(string_of_int content_length);
      f ~name:"Content-Type" ~value:content_type
  end

let form_values_writer assoc_list =
  let content = Uri.encoded_of_query assoc_list in
  content_writer ~content ~content_type:"application/x-www-form-urlencoded"

class virtual readable =
  object
    method virtual headers : Header.t

    method virtual buf_read : Eio.Buf_read.t
  end

let ( let* ) o f = Option.bind o f

let read_content (t : #readable) =
  match Header.(find t#headers content_length) with
  | Some len -> ( try Some (Buf_read.take len t#buf_read) with _ -> None)
  | None -> None

let read_form_values (t : #readable) =
  match
    let* content = read_content t in
    let* content_type = Header.(find t#headers content_type) in
    match Content_type.media_type content_type with
    | "application", "x-www-form-urlencoded" ->
      Some (Uri.query_of_encoded content)
    | _ -> None
  with
  | Some l -> l
  | None -> []
