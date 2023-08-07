let hex_dig t : char =
  match Buf_read.any_char t with
  | ('0' .. '9' | 'A' .. 'F') as c -> c
  | c -> Fmt.failwith "expected HEXDIG but got '%c'" c

let is_unreserved = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '.' | '_' | '~' -> true
  | _ -> false

let is_sub_delims = function
  | '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' -> true
  | _ -> false

let pchar buf buf_read : [ `Ok | `Char of char | `Eof ] =
  match Buf_read.peek_char buf_read with
  | Some c when is_unreserved c || is_sub_delims c || c = ':' || c = '@' ->
    Buf_read.char c buf_read;
    Buffer.add_char buf c;
    `Ok
  | Some ('%' as c) ->
    Buf_read.char c buf_read;
    Buffer.add_char buf c;
    Buffer.add_char buf @@ hex_dig buf_read;
    Buffer.add_char buf @@ hex_dig buf_read;
    `Ok
  | Some c -> `Char c
  | None -> `Eof

let rec segment buf buf_read =
  match pchar buf buf_read with
  | `Ok -> segment buf buf_read
  | `Char _ | `Eof -> Buffer.contents buf

let pct_encode_string ppf s =
  String.iter
    (fun c ->
      if is_unreserved c then Fmt.pf ppf "%c%!" c
      else Fmt.pf ppf "%%%02X%!" @@ Char.code c)
    s

let pct_decode_string s =
  let len = String.length s in
  let buf = Buffer.create len in
  let buf_read = Buf_read.of_string s in
  let rec aux () =
    match Buf_read.peek_char buf_read with
    | Some '%' ->
      Buf_read.char '%' buf_read;
      let hex_digits = Buf_read.take 2 buf_read in
      let c = Char.chr @@ int_of_string ("0x" ^ hex_digits) in
      Buffer.add_char buf c;
      aux ()
    | Some c ->
      Buf_read.char c buf_read;
      Buffer.add_char buf c;
      aux ()
    | None -> Buffer.contents buf
  in
  aux ()

type path = string list

(** [path] is a HTTP URI absolute path string [s]

    [absolute-path = 1*( "/" segment )]

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-uri-references} URI}. *)
let path ?(buf = Buffer.create 10) buf_read =
  Buf_read.char '/' buf_read;
  let path1 = segment buf buf_read in
  let rec loop () =
    match Buf_read.peek_char buf_read with
    | Some '/' ->
      Buf_read.char '/' buf_read;
      let seg = segment buf buf_read in
      Buffer.clear buf;
      seg :: loop ()
    | Some _ | None -> []
  in
  Buffer.clear buf;
  path1 :: loop ()

let make_path l =
  let buf = Buffer.create 64 in
  let ppf = Fmt.with_buffer buf in
  List.map
    (fun comp ->
      pct_encode_string ppf comp;
      let s = Buffer.contents buf in
      Buffer.clear buf;
      s)
    l

let pp_path = Fmt.(any "/" ++ list ~sep:(any "/") string)

let encode_path path = Fmt.str "%a" pp_path path

let path_segments path =
  List.map
    (fun segment ->
      if String.is_infix ~affix:"%" segment then pct_decode_string segment
      else segment)
    path

type query = string

let pct_encode_string ppf s =
  String.iter
    (fun c ->
      if is_unreserved c then Fmt.pf ppf "%c%!" c
      else Fmt.pf ppf "%%%02X%!" @@ Char.code c)
    s

let make_query name_values =
  let buf = Buffer.create 64 in
  let ppf = Fmt.with_buffer buf in
  match name_values with
  | [] -> Buffer.contents buf
  | (name, value) :: name_values ->
    pct_encode_string ppf name;
    Buffer.add_char buf '=';
    pct_encode_string ppf value;
    List.iter
      (fun (name, value) ->
        Buffer.add_char buf '&';
        pct_encode_string ppf name;
        Buffer.add_char buf '=';
        pct_encode_string ppf value)
      name_values;
    Buffer.contents buf

(* [query         = *( pchar / "/" / "?" )] *)
let query buf buf_read =
  let rec loop () =
    match pchar buf buf_read with
    | `Ok -> loop ()
    | `Char ('/' as c) | `Char ('?' as c) ->
      Buf_read.char c buf_read;
      Buffer.add_char buf c;
      loop ()
    | `Char _ | `Eof -> Buffer.contents buf
  in
  match Buf_read.peek_char buf_read with
  | Some '?' ->
    Buf_read.char '?' buf_read;
    Some (loop ())
  | Some _ | None -> None

let query_name_values q =
  let buf_read = Buf_read.of_string q in
  let rec loop () =
    let name =
      Buf_read.take_while
        (function
          | '=' -> false
          | _ -> true)
        buf_read
      |> pct_decode_string
    in
    Buf_read.char '=' buf_read;
    let value =
      Buf_read.take_while
        (function
          | '&' -> false
          | _ -> true)
        buf_read
      |> pct_decode_string
    in
    match Buf_read.peek_char buf_read with
    | Some '&' ->
      Buf_read.char '&' buf_read;
      (name, value) :: loop ()
    | Some _ | None -> [ (name, value) ]
  in
  loop ()

let pp_query = Fmt.string

(* +-- Origin URI --+ *)

type origin_uri = path * query option

let origin_uri s =
  let buf_read = Buf_read.of_string s in
  let buf = Buffer.create 10 in
  let path = path ~buf buf_read in
  Buffer.clear buf;
  let query = query buf buf_read in
  (path, query)

let origin_uri_path (path, _) = path

let origin_uri_query (_, query) = query

let pp_origin_uri fmt origin_uri =
  let fields =
    Fmt.(
      record ~sep:semi
        [ field "Path" (fun (path, _) -> path) pp_path
        ; field "Query" (fun (_, query) -> query) (Fmt.option string)
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt origin_uri

let reg_name buf buf_read : [ `Ok | `Char of char | `Eof ] =
  match Buf_read.peek_char buf_read with
  | Some c when is_unreserved c || is_sub_delims c ->
    Buf_read.char c buf_read;
    Buffer.add_char buf c;
    `Ok
  | Some ('%' as c) ->
    Buf_read.char c buf_read;
    Buffer.add_char buf c;
    Buffer.add_char buf @@ hex_dig buf_read;
    Buffer.add_char buf @@ hex_dig buf_read;
    `Ok
  | Some c -> `Char c
  | None -> `Eof

type host =
  [ `IPv6 of Ipaddr.V6.t
  | `IPv4 of Ipaddr.V4.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]

let pp_host fmt = function
  | `IPv4 addr -> Fmt.pf fmt "IPv4 %a" Ipaddr.V4.pp addr
  | `IPv6 addr -> Fmt.pf fmt "IPv6 %a" Ipaddr.V6.pp addr
  | `Domain_name dn -> Fmt.pf fmt "Domain %a" Domain_name.pp dn

type port = int

type authority = host * port option

let pp_authority fmt auth =
  Fmt.pf fmt "%a" Fmt.(pair ~sep:(any ":") pp_host (option int)) auth

let host buf buf_read =
  match Buf_read.peek_char buf_read with
  | Some '[' ->
    Buf_read.char '[' buf_read;
    let ipv6 =
      Buf_read.take_while
        (function
          | ']' -> false
          | _ -> true)
        buf_read
      |> Ipaddr.V6.of_string_exn
    in
    Buf_read.char ']' buf_read;
    `IPv6 ipv6
  | Some '0' .. '9' ->
    let ipv4 =
      Buf_read.take_while
        (function
          | '0' .. '9' | '.' -> true
          | _ -> false)
        buf_read
      |> Ipaddr.V4.of_string_exn
    in
    `IPv4 ipv4
  | Some _ ->
    let rec domain_name () =
      match reg_name buf buf_read with
      | `Ok -> domain_name ()
      | `Char _ | `Eof -> Buffer.contents buf
    in
    let domain_name = domain_name () |> Domain_name.of_string_exn in
    `Domain_name domain_name
  | None -> Fmt.failwith "[host] invalid host value"

let authority_ buf buf_read =
  Buffer.clear buf;
  let host = host buf buf_read in
  let port =
    match Buf_read.peek_char buf_read with
    | Some ':' ->
      Buf_read.char ':' buf_read;
      Buf_read.take_while
        (function
          | '0' .. '9' -> true
          | _ -> false)
        buf_read
      |> int_of_string_opt
      |> (function
           | Some p -> p
           | None -> Fmt.failwith "[authority] invalid port")
      |> Option.some
    | Some _ | None -> None
  in
  (host, port)

let authority s =
  let buf = Buffer.create 10 in
  let buf_read = Buf_read.of_string s in
  authority_ buf buf_read

let authority_host (host, _) = host

let authority_port (_, port) = port

type scheme =
  [ `Http
  | `Https
  ]

let pp_scheme fmt scheme =
  let s =
    match scheme with
    | `Http -> "http"
    | `Https -> "https"
  in
  Fmt.string fmt s

let scheme_ buf buf_read =
  (match Buf_read.any_char buf_read with
  | ('a' .. 'z' | 'A' .. 'Z') as c -> Buffer.add_char buf c
  | c -> Fmt.failwith "[scheme] expected ALPHA but got '%c'" c);
  let s =
    Buf_read.take_while
      (function
        | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '+' | '-' | '.' -> true
        | _ -> false)
      buf_read
  in
  Buffer.add_string buf s;
  match Buffer.contents buf |> String.Ascii.lowercase with
  | "http" -> `Http
  | "https" -> `Https
  | s -> Fmt.failwith "[scheme] invalid scheme '%s'" s

type absolute_uri = scheme * host * port option * path * query option

let absolute_uri s =
  let buf_read = Buf_read.of_string s in
  let buf = Buffer.create 10 in
  let scheme = scheme_ buf buf_read in
  Buf_read.string "://" buf_read;
  let host, port = authority_ buf buf_read in
  let path =
    let rec path () =
      match Buf_read.peek_char buf_read with
      | Some '/' ->
        Buf_read.char '/' buf_read;
        let seg = segment buf buf_read in
        Buffer.clear buf;
        seg :: path ()
      | Some _ | None -> []
    in
    Buffer.clear buf;
    path ()
  in
  Buffer.clear buf;
  let query = query buf buf_read in
  (scheme, host, port, path, query)

let pp_absolute_uri fmt absolute_uri =
  let fields =
    Fmt.(
      record ~sep:semi
        [ field "Scheme" (fun (scheme, _, _, _, _) -> scheme) pp_scheme
        ; field "Authority"
            (fun (_, host, port, _, _) -> (host, port))
            pp_authority
        ; field "Path" (fun (_, _, _, path, _) -> path) pp_path
        ; field "Query" (fun (_, _, _, _, query) -> query) @@ option string
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt absolute_uri

let path_and_query (_, _, _, path, query) =
  let path = encode_path path in
  match query with
  | Some q -> path ^ "?" ^ q
  | None -> path

let host_and_port (_, host, port, _, _) = (host, port)

type authority_uri = host * port

let authority_uri s =
  let buf_read = Buf_read.of_string s in
  let buf = Buffer.create 10 in
  let host = host buf buf_read in
  Buf_read.char ':' buf_read;
  let port =
    Buf_read.take_while
      (function
        | '0' .. '9' -> true
        | _ -> false)
      buf_read
    |> int_of_string
  in
  (host, port)

let pp_authority_uri fmt authority_form =
  Fmt.(pair ~sep:(any ":") pp_host int) fmt authority_form

type asterisk_uri = char

let asterisk_uri s =
  let buf_read = Buf_read.of_string s in
  match Buf_read.peek_char buf_read with
  | Some '*' ->
    Buf_read.char '*' buf_read;
    '*'
  | Some _ | None -> invalid_arg "[s] doesn't contain valid asterisk-url"

let pp_asterisk_uri fmt _uri = Fmt.pf fmt "*"
