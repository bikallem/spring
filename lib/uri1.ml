let hex_dig t : char =
  match Buf_read.any_char t with
  | ('0' .. '9' | 'A' .. 'F') as c -> c
  | c -> Fmt.failwith "expected HEXDIG but got '%c'" c

let is_reserved = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '.' | '_' | '~' -> true
  | _ -> false

let is_sub_delims = function
  | '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' -> true
  | _ -> false

let pchar buf buf_read : [ `Ok | `Char of char | `Eof ] =
  match Buf_read.peek_char buf_read with
  | Some c when is_reserved c || is_sub_delims c || c = ':' || c = '@' ->
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

(** [absolute_path] is a HTTP URI absolute path string [s]

    [absolute-path = 1*( "/" segment )]

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-uri-references} URI}. *)
let absolute_path ?(buf = Buffer.create 10) buf_read =
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

type absolute_path = string list

let pp_absolute_path = Fmt.(any "/" ++ list ~sep:(any "/") string)

type query = string

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

type origin = absolute_path * query option

let pp_origin fmt origin_form =
  let fields =
    Fmt.(
      record ~sep:semi
        [ field "Path" (fun (path, _) -> path) pp_absolute_path
        ; field "Query" (fun (_, query) -> query) (Fmt.option string)
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt origin_form

let origin buf_read =
  let buf = Buffer.create 10 in
  let absolute_path = absolute_path ~buf buf_read in
  Buffer.clear buf;
  let query = query buf buf_read in
  (absolute_path, query)

let reg_name buf buf_read : [ `Ok | `Char of char | `Eof ] =
  match Buf_read.peek_char buf_read with
  | Some c when is_reserved c || is_sub_delims c ->
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
  [ `IPv6 of Ipaddr.t
  | `IPv4 of Ipaddr.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]

let pp_host fmt = function
  | `IPv4 addr -> Fmt.pf fmt "IPv4 %a" Ipaddr.pp addr
  | `IPv6 addr -> Fmt.pf fmt "IPv6 %a" Ipaddr.pp addr
  | `Domain_name dn -> Fmt.pf fmt "Domain %a" Domain_name.pp dn

type port = int

type authority = host * port option

let pp_authority fmt auth =
  Fmt.pf fmt "%a" Fmt.(pair ~sep:(any ": ") pp_host (option int)) auth

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
      |> Ipaddr.of_string_exn
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
      |> Ipaddr.of_string_exn
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

let authority buf_read = authority_ (Buffer.create 10) buf_read

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

let scheme buf buf_read =
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

type absolute_form = scheme * authority * absolute_path * query option

let pp_absolute_form fmt absolute_form =
  let fields =
    Fmt.(
      record ~sep:semi
        [ field "Scheme" (fun (scheme, _, _, _) -> scheme) pp_scheme
        ; field "Authority" (fun (_, authority, _, _) -> authority) pp_authority
        ; field "Path"
            (fun (_, _, absolute_path, _) -> absolute_path)
            pp_absolute_path
        ; field "Query" (fun (_, _, _, query) -> query) @@ option string
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt absolute_form

let absolute_form buf_read =
  let buf = Buffer.create 10 in
  let scheme = scheme buf buf_read in
  Buf_read.string "://" buf_read;
  let authority = authority_ buf buf_read in
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
  (scheme, authority, path, query)

type authority_form = host * port

let pp_authority_form fmt authority_form =
  Fmt.(pair ~sep:(any ":") pp_host int) fmt authority_form

let authority_form buf_read =
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

let asterisk_form buf_read =
  Buf_read.char '*' buf_read;
  '*'
