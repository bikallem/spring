class virtual t (version : Version.t) (headers : Header.t) (status : Status.t) =
  object
    val headers = headers
    method headers = headers
    method version = version
    method status = status
    method update headers' = {<headers = headers'>}
  end

let version (t : #t) = t#version
let headers (t : #t) = t#headers
let status (t : #t) = t#status

let find_set_cookie_ name headers =
  Header.(find_all headers set_cookie)
  |> List.find_opt (fun sc -> String.equal name @@ Set_cookie.name sc)

let find_set_cookie name (t : #t) = find_set_cookie_ name t#headers

exception Closed

class virtual client_response version headers status buf_read =
  let closed = ref false in
  object
    inherit t version headers status
    inherit Body.readable
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

class virtual server_response version headers status =
  object
    inherit t version headers status
    inherit Body.writable
  end

let add_set_cookie v (t : #server_response) =
  Header.(add t#headers set_cookie v) |> t#update

let remove_set_cookie name (t : #server_response) =
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
  let headers = aux (Header.to_list t#headers) in
  let headers = (headers :> (string * string) list) in
  t#update (Header.of_list headers)

let field lbl v =
  let open Easy_format in
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

module Server = struct
  type t =
    { version : Version.t
    ; status : Status.t
    ; headers : Header.t
    ; body : Body.writable'
    }

  let make
      ?(version = Version.http1_1)
      ?(status = Status.ok)
      ?(headers = Header.empty)
      body =
    { version; status; headers; body }

  let find_set_cookie name t = find_set_cookie_ name t.headers

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
    let body = Body.content_writer' content_type content in
    make body

  let html content =
    let content_type =
      Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "html")
    in
    let body = Body.content_writer' content_type content in
    make body

  let ohtml o =
    let buf = Buffer.create 10 in
    o buf;
    let content = Buffer.contents buf in
    html content

  let chunked_response ~ua_supports_trailer write_chunk write_trailer =
    Chunked.writable ~ua_supports_trailer write_chunk write_trailer |> make

  let none_body_response status =
    let headers = Header.singleton ~name:"Content-Length" ~value:"0" in
    make ~headers ~status Body.none'

  let not_found = none_body_response Status.not_found
  let internal_server_error = none_body_response Status.internal_server_error
  let bad_request = none_body_response Status.bad_request

  let write t w =
    let version = Version.to_string t.version in
    let status = Status.to_string t.status in
    Eio.Buf_write.string w version;
    Eio.Buf_write.char w ' ';
    Eio.Buf_write.string w status;
    Eio.Buf_write.string w "\r\n";
    t.body.write_headers w;
    Header.write w t.headers;
    Eio.Buf_write.string w "\r\n";
    t.body.write_body w

  let pp fmt t =
    let open Easy_format in
    let fields =
      [ field "Version" (Version.to_string t.version)
      ; field "Status" (Status.to_string t.status)
      ; Label
          ( (Atom ("Headers :", atom), { label with label_break = `Always })
          , Header.easy_fmt t.headers )
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
end

let server_response
    ?(version = Version.http1_1)
    ?(headers = Header.empty)
    ?(status = Status.ok)
    (body : #Body.writable) : server_response =
  object
    inherit server_response version headers status
    method write_body = body#write_body
    method write_header = body#write_header
  end

let write_header w : < f : 'a. 'a Header.header -> 'a -> unit > =
  object
    method f : 'a. 'a Header.header -> 'a -> unit =
      fun hdr v -> Header.write_header w hdr v
  end

let write (t : #server_response) w =
  let version = Version.to_string t#version in
  let status = Status.to_string t#status in
  Eio.Buf_write.string w version;
  Eio.Buf_write.char w ' ';
  Eio.Buf_write.string w status;
  Eio.Buf_write.string w "\r\n";
  t#write_header (write_header w);
  Header.write w t#headers;
  Eio.Buf_write.string w "\r\n";
  t#write_body w

let text content =
  let content_type =
    Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "plain")
  in
  let body = Body.content_writer content_type content in
  server_response body

let html content =
  let content_type =
    Content_type.make ~params:[ ("charset", "uf-8") ] ("text", "html")
  in
  let body = Body.content_writer content_type content in
  server_response body

let ohtml o =
  let buf = Buffer.create 10 in
  o buf;
  let content = Buffer.contents buf in
  html content

let none_body_response status =
  let headers = Header.singleton ~name:"Content-Length" ~value:"0" in
  server_response ~headers ~status Body.none

let not_found = none_body_response Status.not_found
let internal_server_error = none_body_response Status.internal_server_error
let bad_request = none_body_response Status.bad_request

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
