type 'a t =
  { version : Version.t
  ; status : Status.t
  ; headers : Headers.t
  ; x : 'a
  }

let version t = t.version

let status t = t.status

let headers t = t.headers

let find_set_cookie_ name headers =
  Headers.(find_all set_cookie headers)
  |> List.find_opt (fun sc -> String.equal name @@ Set_cookie.name sc)

let find_set_cookie name t = find_set_cookie_ name t.headers

let pp fmt t =
  let fields =
    Fmt.(
      record ~sep:semi
        [ Fmt.field "Version" (fun t -> t.version) Version.pp
        ; Fmt.field "Status" (fun t -> t.status) Status.pp
        ; Fmt.field "Headers" (fun t -> t.headers) Headers.pp
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt t

type client =
  { buf_read : Eio.Buf_read.t
  ; mutable closed : bool
  }

let make_client_response
    ?(version = Version.http1_1)
    ?(status = Status.ok)
    ?(headers = Headers.empty)
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
  let version = (Version.parse <* Buf_read.space) buf_read in
  let status = Buf_read.(p_status <* crlf) buf_read in
  let headers = Headers.parse buf_read in
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
    ?(headers = Headers.empty)
    body =
  { version; status; headers; x = body }

let body t = t.x

let add_set_cookie v t =
  let headers = Headers.(add set_cookie v t.headers) in
  { t with headers }

let remove_set_cookie name t =
  let[@tail_mod_cons] rec aux = function
    | [] -> []
    | ((hdr_name, v) as x) :: tl ->
      let nm =
        Headers.(Definition.name set_cookie |> Definition.lname_of_name)
      in
      if
        Headers.Definition.lname_equal hdr_name nm
        && (String.equal name @@ Set_cookie.(decode v |> name))
      then tl
      else x :: aux tl
  in
  let headers = aux (Headers.to_list t.headers) in
  let headers = Headers.of_list (headers :> (string * string) list) in
  { t with headers }

let text content =
  let content_type =
    Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "plain")
  in
  let body = Body.writable_content content_type content in
  make_server_response body

let html content =
  let content_type =
    Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "html")
  in
  let body = Body.writable_content content_type content in
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
  let headers = Headers.singleton ~name:"Content-Length" ~value:"0" in
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
  Headers.write w t.headers;
  Eio.Buf_write.string w "\r\n";
  Body.write_body w t.x
