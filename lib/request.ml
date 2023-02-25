(** [request] is the common request object *)
let host_port_to_string (host, port) =
  match port with
  | Some p -> Format.sprintf "%s:%d" host p
  | None -> host

class virtual t =
  object
    method virtual version : Version.t

    method virtual headers : Header.t

    method virtual meth : Method.t

    method virtual resource : string

    method virtual pp : Format.formatter -> unit
  end

type host_port = string * int option

let version (t : #t) = t#version

let headers (t : #t) = t#headers

let meth (t : #t) = t#meth

let resource (t : #t) = t#resource

let supports_chunked_trailers (t : #t) =
  match Header.(find t#headers te) with
  | Some te' -> Te_hdr.(exists te' trailers)
  | None -> false

let keep_alive (t : #t) =
  match (t#version :> int * int) with
  | 1, 1 -> true
  | 1, 0 -> (
    match Header.(find t#headers connection) with
    | Some v ->
      String.split_on_char ',' v
      |> List.exists (fun tok ->
             let tok = String.(trim tok |> lowercase_ascii) in
             String.equal tok "keep-alive")
    | None -> false)
  | _ -> false

class virtual client_request =
  object
    inherit t

    inherit Body.writable

    method virtual host : string

    method virtual port : int option
  end

let field lbl v =
  let open Easy_format in
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let fields (t : #t) (f : unit -> Easy_format.t list) =
  let open Easy_format in
  let l =
    [ field "Version" (Version.to_string t#version)
    ; field "Method" (Method.to_string t#meth :> string)
    ; field "URI" t#resource
    ; Label
        ( (Atom ("Headers :", atom), { label with label_break = `Always })
        , Header.easy_fmt t#headers )
    ]
  in
  l @ f ()

let pp_fields fmt fields =
  let open Easy_format in
  let list_p =
    { list with
      align_closing = true
    ; indent_body = 2
    ; wrap_body = `Force_breaks_rec
    }
  in
  Pretty.to_formatter fmt (List (("{", ";", "}", list_p), fields))

let client_request ?(version = Version.http1_1) ?(headers = Header.empty) ?port
    ~host ~resource (meth : Method.t) body =
  object (self)
    inherit client_request as _super

    val headers = headers

    method version = version

    method headers = headers

    method meth = meth

    method resource = resource

    method host = host

    method port = port

    method write_body = body#write_body

    method write_header = body#write_header

    method pp fmt =
      let fields =
        fields self @@ fun () ->
        [ field "Host" (host_port_to_string (host, port)) ]
      in
      pp_fields fmt fields
  end

let client_host_port (t : #client_request) = (t#host, t#port)

let parse_url url =
  if String.starts_with ~prefix:"https" url then
    raise @@ Invalid_argument "url: https protocol not supported";
  let url =
    if
      (not (String.starts_with ~prefix:"http" url))
      && not (String.starts_with ~prefix:"//" url)
    then "//" ^ url
    else url
  in
  let u = Uri.of_string url in
  let host, port =
    match (Uri.host u, Uri.port u) with
    | None, _ -> raise @@ Invalid_argument "invalid url: host not defined"
    | Some host, port when String.length host > 0 -> (host, port)
    | _ -> raise @@ Invalid_argument "invalid url: host not defined"
  in
  (host, port, Uri.path_and_query u)

type url = string

let get url =
  let host, port, resource = parse_url url in
  client_request ?port Method.get ~host ~resource Body.none

let head url =
  let host, port, resource = parse_url url in
  client_request ?port Method.head ~host ~resource Body.none

let post body url =
  let host, port, resource = parse_url url in
  client_request ?port Method.post ~host ~resource body

let post_form_values form_values url =
  let body = Body.form_values_writer form_values in
  post body url

let write_header w ~name ~value = Buf_write.write_header w name value

let write (t : #client_request) w =
  let headers = Header.(add_unless_exists t#headers user_agent "cohttp-eio") in
  let te' = Te_hdr.(singleton trailers) in
  let headers = Header.(add headers te te') in
  let headers = Header.(add headers connection "TE") in
  let headers = Header.clean_dup headers in
  let meth = (Method.to_string t#meth :> string) in
  let version = Version.to_string t#version in
  Buf_write.string w meth;
  Buf_write.char w ' ';
  Buf_write.string w t#resource;
  Buf_write.char w ' ';
  Buf_write.string w version;
  Buf_write.string w "\r\n";
  (* The first header is a "Host" header. *)
  let host =
    match t#port with
    | Some port -> t#host ^ ":" ^ string_of_int port
    | None -> t#host
  in
  Buf_write.write_header w "host" host;
  t#write_header (write_header w);
  Buf_write.write_headers w headers;
  Buf_write.string w "\r\n";
  t#write_body w

class virtual server_request =
  object
    inherit t

    inherit Body.readable

    method virtual client_addr : Eio.Net.Sockaddr.stream
  end

let buf_read (t : #server_request) = t#buf_read

let client_addr (t : #server_request) = t#client_addr

let server_request ?(version = Version.http1_1) ?(headers = Header.empty)
    ~resource meth client_addr buf_read =
  object (self)
    inherit server_request

    method version = version

    method headers = headers

    method meth = meth

    method resource = resource

    method client_addr = client_addr

    method buf_read = buf_read

    method pp fmt =
      let sock_addr =
        let buf = Buffer.create 10 in
        let fmt = Format.formatter_of_buffer buf in
        Format.fprintf fmt "%a" Eio.Net.Sockaddr.pp client_addr;
        Format.pp_print_flush fmt ();
        Buffer.contents buf
      in
      let fields =
        fields self @@ fun () -> [ field "Client Address" sock_addr ]
      in
      pp_fields fmt fields
  end

open Eio.Buf_read.Syntax

let take_while1 p r =
  match Buf_read.take_while p r with
  | "" -> raise End_of_file
  | x -> x

let token =
  take_while1 (function
    | '0' .. '9'
    | 'a' .. 'z'
    | 'A' .. 'Z'
    | '!'
    | '#'
    | '$'
    | '%'
    | '&'
    | '\''
    | '*'
    | '+'
    | '-'
    | '.'
    | '^'
    | '_'
    | '`'
    | '|'
    | '~' -> true
    | _ -> false)

let space = Buf_read.char '\x20'

let http_meth =
  let+ meth = token <* space in
  Method.make meth

let http_resource = take_while1 (fun c -> c != ' ') <* space

let parse client_addr (r : Buf_read.t) : server_request =
  let meth = http_meth r in
  let resource = http_resource r in
  let version = (Version.p <* Buf_read.crlf) r in
  let headers = Header.parse r in
  server_request ~version ~headers ~resource meth client_addr r

let pp fmt (t : #t) = t#pp fmt
