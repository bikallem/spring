class virtual t =
  object
    method virtual version : Version.t

    method virtual headers : Header.t

    method virtual status : Status.t
  end

let version (t : #t) = t#version

let headers (t : #t) = t#headers

let status (t : #t) = t#status

exception Closed

class client_response version headers status buf_read =
  let closed = ref false in
  object
    inherit t

    inherit Body.readable

    method version = version

    method headers = headers

    method status = status

    method buf_read = if !closed then raise Closed else buf_read

    method body_closed = !closed

    method close_body = closed := true
  end

(* https://datatracker.ietf.org/doc/html/rfc7230#section-3.1.2 *)

open Buf_read.Syntax

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false

let reason_phrase =
  Buf_read.take_while (function
    | '\x21' .. '\x7E' | '\t' | ' ' -> true
    | _ -> false)

let p_status =
  let* status = Buf_read.take_while1 is_digit in
  let+ phrase = Buf_read.space *> reason_phrase in
  Status.make (int_of_string status) phrase

let parse buf_read =
  let open Eio.Buf_read.Syntax in
  let version = (Version.p <* Buf_read.space) buf_read in
  let status = Buf_read.(p_status <* crlf) buf_read in
  let headers = Header.parse buf_read in
  (version, headers, status)

let close_body (t : #client_response) = t#close_body

let body_closed (t : #client_response) = t#body_closed

class virtual server_response =
  object
    inherit t

    inherit Body.writable
  end

let server_response ?(version = Version.http1_1) ?(headers = Header.empty)
    ?(status = Status.ok) (body : #Body.writable) : server_response =
  object
    method version = version

    method headers = headers

    method status = status

    method write_body = body#write_body

    method write_header = body#write_header
  end

let chunked_response ~ua_supports_trailer write_chunk write_trailer =
  Chunked_body.writable ~ua_supports_trailer write_chunk write_trailer
  |> server_response

let write_header w ~name ~value =
  Header.write_header (Buf_write.string w) name value

let write (t : #server_response) w =
  let version = Version.to_string t#version in
  let status = Status.to_string t#status in
  Buf_write.string w version;
  Buf_write.char w ' ';
  Buf_write.string w status;
  Buf_write.string w "\r\n";
  t#write_header (write_header w);
  Header.write t#headers (Buf_write.string w);
  Buf_write.string w "\r\n";
  t#write_body w

let text content =
  server_response
    (Body.content_writer ~content ~content_type:"text/plain; charset=UTF-8")

let html content =
  server_response
    (Body.content_writer ~content ~content_type:"text/html; charset=UTF-8")

let none_body_response status =
  let headers = Header.singleton ~name:"Content-Length" ~value:"0" in
  server_response ~headers ~status Body.none

let not_found = none_body_response Status.not_found

let internal_server_error = none_body_response Status.internal_server_error

let bad_request = none_body_response Status.bad_request

let field lbl v =
  let open Easy_format in
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let pp fmt (t : #t) =
  let open Easy_format in
  let fields =
    [ field "Version" (Version.to_string t#version)
    ; field "Status" (Status.to_string t#status)
    ; Label
        ( (Atom ("Headers :", atom), { label with label_break = `Always })
        , Header.easy_fmt t#headers )
    ]
  in
  let list_p =
    { list with
      align_closing = true
    ; indent_body = 2
    ; wrap_body = `Force_breaks_rec
    }
  in
  Pretty.to_formatter fmt (List (("{", ";", "}", list_p), fields))
