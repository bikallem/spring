type 'a t =
  { version : Version.t
  ; status : Status.t
  ; headers : Header.t
  ; x : 'a
  }

let version t = t.version

let status t = t.status

let headers t = t.headers

let find_set_cookie_ name headers =
  Header.(find_all headers set_cookie)
  |> List.find_opt (fun sc -> String.equal name @@ Set_cookie.name sc)

let field lbl v =
  let open Easy_format in
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let pp_ version status headers fmt =
  let open Easy_format in
  let fields =
    [ field "Version" (Version.to_string version)
    ; field "Status" (Status.to_string status)
    ; Label
        ( (Atom ("Headers :", atom), { label with label_break = `Always })
        , Header.easy_fmt headers )
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

let find_set_cookie name t = find_set_cookie_ name t.headers

let pp fmt t = pp_ t.version t.status t.headers fmt

type client =
  { buf_read : Eio.Buf_read.t
  ; mutable closed : bool
  }

let make_client_response
    ?(version = Version.http1_1)
    ?(status = Status.ok)
    ?(headers = Header.empty)
    buf_read =
  let client = { buf_read; closed = false } in
  { version; status; headers; x = client }

open Buf_read.Syntax

(* https://datatracker.ietf.org/doc/html/rfc7230#section-3.1.2 *)
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

let parse_client_response buf_read =
  let version = (Version.p <* Buf_read.space) buf_read in
  let status = Buf_read.(p_status <* crlf) buf_read in
  let headers = Header.parse buf_read in
  let client = { buf_read; closed = false } in
  { version; headers; status; x = client }

exception Closed

let closed t = t.x.closed

let close t = t.x.closed <- true

let readable t = Body.make_readable t.headers t.x.buf_read

let buf_read t = if t.x.closed then raise Closed else t.x.buf_read

(* Server Response *)

type server = Body.writable

let make_server_response
    ?(version = Version.http1_1)
    ?(status = Status.ok)
    ?(headers = Header.empty)
    body =
  { version; status; headers; x = body }

let body t = t.x

let add_set_cookie v t =
  let headers = Header.(add t.headers set_cookie v) in
  { t with headers }

let remove_set_cookie name t =
  let[@tail_mod_cons] rec aux = function
    | [] -> []
    | ((hdr_name, v) as x) :: tl ->
      let nm = Header.(name set_cookie |> lname_of_name) in
      if
        Header.lname_equal hdr_name nm
        && (String.equal name @@ Set_cookie.(decode v |> name))
      then tl
      else x :: aux tl
  in
  let headers = aux (Header.to_list t.headers) in
  let headers = Header.of_list (headers :> (string * string) list) in
  { t with headers }

let text content =
  let content_type =
    Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "plain")
  in
  let body = Body.content_writer content_type content in
  make_server_response body

let html content =
  let content_type =
    Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "html")
  in
  let body = Body.content_writer content_type content in
  make_server_response body

let ohtml o =
  let buf = Buffer.create 10 in
  o buf;
  let content = Buffer.contents buf in
  html content

let chunked_response ~ua_supports_trailer write_chunk write_trailer =
  Chunked.writable ~ua_supports_trailer write_chunk write_trailer
  |> make_server_response

let none_body_response status =
  let headers = Header.singleton ~name:"Content-Length" ~value:"0" in
  make_server_response ~headers ~status Body.none

let not_found = none_body_response Status.not_found

let internal_server_error = none_body_response Status.internal_server_error

let bad_request = none_body_response Status.bad_request

let write_server_response w (t : server t) =
  let version = Version.to_string t.version in
  let status = Status.to_string t.status in
  Eio.Buf_write.string w version;
  Eio.Buf_write.char w ' ';
  Eio.Buf_write.string w status;
  Eio.Buf_write.string w "\r\n";
  Body.write_headers w t.x;
  Header.write w t.headers;
  Eio.Buf_write.string w "\r\n";
  Body.write_body w t.x
