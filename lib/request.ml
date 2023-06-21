(** [request] is the common request object *)
let host_port_to_string (host, port) =
  match port with
  | Some p -> Format.sprintf "%s:%d" host p
  | None -> host

type resource = string

class virtual t version headers meth resource =
  object
    val headers = headers
    method headers : Header.t = headers
    method version : Version.t = version
    method meth : Method.t = meth
    method resource : string = resource
    method update headers' = {<headers = headers'>}
    method virtual pp : Format.formatter -> unit
  end

let supports_chunked_trailers_ headers =
  match Header.(find_opt headers te) with
  | Some te' -> Te.(exists te' trailers)
  | None -> false

let keep_alive_ (version : Version.t) headers =
  let close =
    let open Option.Syntax in
    match
      let+ connection = Header.(find_opt headers connection) in
      String.cuts ~sep:"," connection
      |> List.exists (fun tok ->
             let tok = String.(trim tok |> Ascii.lowercase) in
             String.equal tok "close")
    with
    | Some close -> close
    | None -> false
  in
  match (close, (version :> int * int)) with
  | true, _ -> false
  | false, (1, 0) -> false
  | false, _ -> true

let find_cookie_ name headers =
  let open Option.Syntax in
  let* cookie = Header.(find_opt headers cookie) in
  Cookie.find_opt name cookie

type host_port = string * int option

let version (t : #t) = t#version
let headers (t : #t) = t#headers
let meth (t : #t) = t#meth
let resource (t : #t) = t#resource

let supports_chunked_trailers (t : #t) =
  match Header.(find_opt t#headers te) with
  | Some te' -> Te.(exists te' trailers)
  | None -> false

let keep_alive (t : #t) =
  match (t#version :> int * int) with
  | 1, 1 -> true
  | 1, 0 -> (
    match Header.(find_opt t#headers connection) with
    | Some v ->
      String.cuts ~sep:"," v
      |> List.exists (fun tok ->
             let tok = String.(trim tok |> Ascii.lowercase) in
             String.equal tok "keep-alive")
    | None -> false)
  | _ -> false

let find_cookie name (t : #t) =
  let open Option.Syntax in
  let* cookie = Header.(find_opt t#headers cookie) in
  Cookie.find_opt name cookie

let field lbl v =
  let open Easy_format in
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let fields version meth resource headers (f : unit -> Easy_format.t list) =
  let open Easy_format in
  let l =
    [ field "Version" (Version.to_string version)
    ; field "Method" (Method.to_string meth :> string)
    ; field "URI" resource
    ; Label
        ( (Atom ("Headers :", atom), { label with label_break = `Always })
        , Header.easy_fmt headers )
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

module Client = struct
  type t =
    { meth : Method.t
    ; resource : resource
    ; version : Version.t
    ; headers : Header.t
    ; host : string
    ; port : int option
    ; body : Body.writable
    }

  let make
      ?(version = Version.http1_1)
      ?(headers = Header.empty)
      ?port
      ~host
      ~resource
      meth
      body =
    { meth; resource; version; headers; host; port; body }

  let supports_chunked_trailers t = supports_chunked_trailers_ t.headers
  let keep_alive t = keep_alive_ t.version t.headers
  let find_cookie name t = find_cookie_ name t.headers

  let add_cookie ~name ~value t =
    let cookie_hdr =
      match Header.(find_opt t.headers cookie) with
      | Some cookie_hdr -> cookie_hdr
      | None -> Cookie.empty
    in
    let cookie_hdr = Cookie.add ~name ~value cookie_hdr in
    let headers = Header.(replace t.headers cookie cookie_hdr) in
    { t with headers }

  let remove_cookie cookie_name t =
    let cookie' =
      match Header.(find_opt t.headers cookie) with
      | Some cookie' -> cookie'
      | None -> Cookie.empty
    in
    let cookie' = Cookie.remove ~name:cookie_name cookie' in
    let headers = Header.(replace t.headers cookie cookie') in
    { t with headers }

  let write t w =
    let headers =
      Header.(add_unless_exists t.headers user_agent "cohttp-eio")
    in
    let te' = Te.(singleton trailers) in
    let headers = Header.(add headers te te') in
    let headers = Header.(add headers connection "TE") in
    let meth = (Method.to_string t.meth :> string) in
    let version = Version.to_string t.version in
    Eio.Buf_write.string w meth;
    Eio.Buf_write.char w ' ';
    Eio.Buf_write.string w t.resource;
    Eio.Buf_write.char w ' ';
    Eio.Buf_write.string w version;
    Eio.Buf_write.string w "\r\n";
    (* The first header is a "Host" header. *)
    let host' = host_port_to_string (t.host, t.port) in
    Header.(write_header w host host');
    t.body.write_headers w;
    Header.write w headers;
    Eio.Buf_write.string w "\r\n";
    t.body.write_body w

  let pp fmt t =
    let fields =
      fields t.version t.meth t.resource t.headers @@ fun () ->
      [ field "Host" (host_port_to_string (t.host, t.port)) ]
    in
    pp_fields fmt fields
end

module Server = struct
  type t =
    { meth : Method.t
    ; resource : resource
    ; version : Version.t
    ; headers : Header.t
    ; client_addr : Eio.Net.Sockaddr.stream
    ; buf_read : Eio.Buf_read.t
    ; session_data : Session.session_data option
    }

  let make
      ?(version = Version.http1_1)
      ?(headers = Header.empty)
      ?session_data
      ~resource
      meth
      client_addr
      buf_read =
    { meth; resource; version; headers; client_addr; buf_read; session_data }

  let keep_alive t = keep_alive_ t.version t.headers

  let parse ?session client_addr (buf_read : Buf_read.t) =
    let open Eio.Buf_read.Syntax in
    let meth =
      (let+ meth = Buf_read.(token <* space) in
       Method.make meth)
        buf_read
    in
    let resource =
      Buf_read.(take_while1 (fun c -> c != ' ') <* space) buf_read
    in
    let version = (Version.p <* Buf_read.crlf) buf_read in
    let headers = Header.parse buf_read in
    let session_data =
      let open Option.Syntax in
      let* session = session in
      let* cookie = Header.(find_opt headers cookie) in
      let+ session_data = Cookie.find_opt session#cookie_name cookie in
      Session.decode session_data session
    in
    make ?session_data ~version ~headers ~resource meth client_addr buf_read

  let pp fmt t =
    let sock_addr =
      let buf = Buffer.create 10 in
      let fmt = Format.formatter_of_buffer buf in
      Format.fprintf fmt "%a" Eio.Net.Sockaddr.pp t.client_addr;
      Format.pp_print_flush fmt ();
      Buffer.contents buf
    in
    let fields =
      fields t.version t.meth t.resource t.headers @@ fun () ->
      [ field "Client Address" sock_addr ]
    in
    pp_fields fmt fields
end

class virtual server_request ?session_data version headers meth resource =
  object
    inherit t version headers meth resource
    inherit Body.readable
    val mutable session_data : Session.session_data option = session_data

    method add_session_data ~name ~value =
      let session_data' =
        match session_data with
        | Some v -> v
        | None -> Session.Data.empty |> Session.Data.add name value
      in
      session_data <- Some session_data'

    method find_session_data name =
      let open Option.Syntax in
      let* session_data = session_data in
      Session.Data.find_opt name session_data

    method session_data = session_data
    method virtual client_addr : Eio.Net.Sockaddr.stream
  end

let buf_read (t : #server_request) = t#buf_read
let client_addr (t : #server_request) = t#client_addr

let add_session_data ~name ~value (t : #server_request) =
  t#add_session_data ~name ~value

let find_session_data name (t : #server_request) = t#find_session_data name
let session_data (t : #server_request) = t#session_data

let server_request
    ?(version = Version.http1_1)
    ?(headers = Header.empty)
    ?session_data
    ~resource
    meth
    client_addr
    buf_read =
  object (self)
    inherit server_request ?session_data version headers meth resource
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
        fields self#version self#meth self#resource self#headers @@ fun () ->
        [ field "Client Address" sock_addr ]
      in
      pp_fields fmt fields
  end

open Eio.Buf_read.Syntax

let http_meth =
  let+ meth = Buf_read.(token <* space) in
  Method.make meth

let http_resource = Buf_read.(take_while1 (fun c -> c != ' ') <* space)

let parse ?session client_addr (r : Buf_read.t) : server_request =
  let meth = http_meth r in
  let resource = http_resource r in
  let version = (Version.p <* Buf_read.crlf) r in
  let headers = Header.parse r in
  let session_data =
    let open Option.Syntax in
    let* session = session in
    let* cookie = Header.(find_opt headers cookie) in
    let+ session_data = Cookie.find_opt session#cookie_name cookie in
    Session.decode session_data session
  in
  server_request ?session_data ~version ~headers ~resource meth client_addr r

let pp fmt (t : #t) = t#pp fmt
