type resource = string

type 'a t =
  { meth : Method.t
  ; resource : resource
  ; version : Version.t
  ; headers : Headers.t
  ; x : 'a
  ; pp : Format.formatter -> 'a t -> unit
  }

let meth t = t.meth

let resource t = t.resource

let version t = t.version

let headers t = t.headers

let supports_chunked_trailers t =
  match Headers.(find_opt te t.headers) with
  | Some te' -> Te.(exists te' trailers)
  | None -> false

let keep_alive t =
  let close =
    let open Option.Syntax in
    let* connection = Headers.(find_opt connection t.headers) in
    let conn_vals = String.cuts ~sep:"," connection in
    if List.exists (String.equal "close") conn_vals then Some true
    else if List.exists (String.equal "keep-alive") conn_vals then Some false
    else None
  in
  match (close, (t.version :> int * int)) with
  | Some true, _ -> false
  | Some false, _ -> true
  | None, (1, 0) -> false
  | None, _ -> true

let find_cookie name t =
  let open Option.Syntax in
  let* cookie = Headers.(find_opt cookie t.headers) in
  Cookie.find_opt name cookie

type client =
  { host : string
  ; port : int option
  ; body : Body.writable
  }

let host_port_to_string (host, port) =
  match port with
  | Some p -> Format.sprintf "%s:%d" host p
  | None -> host

let pp_fields x_field_pp fmt t =
  let fields =
    Fmt.(
      record ~sep:semi
        [ Fmt.field "Method" (fun t -> t.meth) Method.pp
        ; Fmt.field "Resource" (fun t -> t.resource) Fmt.string
        ; Fmt.field "Version" (fun t -> t.version) Version.pp
        ; Fmt.field "Headers" (fun t -> t.headers) Headers.pp
        ; x_field_pp
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt t

let make_client_request
    ?(version = Version.http1_1)
    ?(headers = Headers.empty)
    ?port
    ~host
    ~resource
    meth
    body =
  let client = { host; port; body } in
  let pp =
    Fmt.(
      field "Host" (fun t -> host_port_to_string (t.x.host, t.x.port)) string)
    |> pp_fields
  in
  { meth; resource; version; headers; x = client; pp }

let host t = t.x.host

let port t = t.x.port

let add_cookie ~name ~value t =
  let cookie_hdr =
    match Headers.(find_opt cookie t.headers) with
    | Some cookie_hdr -> cookie_hdr
    | None -> Cookie.empty
  in
  let cookie_hdr = Cookie.add ~name ~value cookie_hdr in
  let headers = Headers.(replace cookie cookie_hdr t.headers) in
  { t with headers }

let remove_cookie cookie_name t =
  let cookie' =
    match Headers.(find_opt cookie t.headers) with
    | Some cookie' -> cookie'
    | None -> Cookie.empty
  in
  let cookie' = Cookie.remove ~name:cookie_name cookie' in
  let headers = Headers.(replace cookie cookie' t.headers) in
  { t with headers }

let write_client_request t w =
  let te' = Te.(singleton trailers) in
  let headers =
    Headers.(add_unless_exists user_agent "spring") t.headers
    |> Headers.(add te te')
    |> Headers.(add connection "TE")
  in
  let meth = (Method.to_string t.meth :> string) in
  let version = Version.to_string t.version in
  Eio.Buf_write.string w meth;
  Eio.Buf_write.char w ' ';
  Eio.Buf_write.string w t.resource;
  Eio.Buf_write.char w ' ';
  Eio.Buf_write.string w version;
  Eio.Buf_write.string w "\r\n";
  (* The first header is a "Host" header. *)
  let host' = host_port_to_string (t.x.host, t.x.port) in
  Headers.(write_header w host host');
  Body.write_headers w t.x.body;
  Headers.write w headers;
  Eio.Buf_write.string w "\r\n";
  Body.write_body w t.x.body

type server =
  { client_addr : Eio.Net.Sockaddr.stream
  ; buf_read : Eio.Buf_read.t
  ; mutable session_data : Session.session_data option
  }

let make_server_request
    ?(version = Version.http1_1)
    ?(headers = Headers.empty)
    ?session_data
    ~resource
    meth
    client_addr
    buf_read =
  let server = { client_addr; buf_read; session_data } in
  let pp =
    Fmt.(field "Client Address" (fun t -> t.x.client_addr) Eio.Net.Sockaddr.pp)
    |> pp_fields
  in
  { meth; resource; version; headers; x = server; pp }

let client_addr t = t.x.client_addr

let session_data t = t.x.session_data

let add_session_data ~name ~value t =
  let session_data' =
    match t.x.session_data with
    | Some v -> v
    | None -> Session.Data.empty |> Session.Data.add name value
  in
  t.x.session_data <- Some session_data'

let replace_session_data data t = t.x.session_data <- Some data

let find_session_data name t =
  Option.bind t.x.session_data (fun session_data ->
      Session.Data.find_opt name session_data)

let readable t = Body.make_readable t.headers t.x.buf_read

let buf_read t = t.x.buf_read

let parse_server_request ?session client_addr (buf_read : Buf_read.t) =
  let open Eio.Buf_read.Syntax in
  let meth =
    (let+ meth = Buf_read.(token <* space) in
     Method.make meth)
      buf_read
  in
  let resource = Buf_read.(take_while1 (fun c -> c != ' ') <* space) buf_read in
  let version = (Version.p <* Buf_read.crlf) buf_read in
  let headers = Headers.parse buf_read in
  let session_data =
    let open Option.Syntax in
    let* session = session in
    let* cookie = Headers.(find_opt cookie headers) in
    let cookie_name = Session.cookie_name session in
    let+ session_data = Cookie.find_opt cookie_name cookie in
    Session.decode session_data session
  in
  make_server_request ?session_data ~version ~headers ~resource meth client_addr
    buf_read

let pp fmt t = t.pp fmt t
