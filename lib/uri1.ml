let hex_dig t : char =
  match Buf_read.any_char t with
  | ('0' .. '9' | 'A' .. 'F') as c -> c
  | c -> Fmt.failwith "expected HEXDIG but got '%c'" c

let pchar buf buf_read : [ `Ok | `End ] =
  match Buf_read.peek_char buf_read with
  | Some
      (( 'a' .. 'z'
       | 'A' .. 'Z'
       | '0' .. '9'
       | '-' | '.' | '_' | '~' (* unreserved *)
       | '!'
       | '$'
       | '&'
       | '\''
       | '('
       | ')'
       | '*'
       | '+'
       | ','
       | ';'
       | '=' (* sub-delims *)
       | ':' | '@' ) as c) ->
    Buf_read.char c buf_read;
    Buffer.add_char buf c;
    `Ok
  | Some ('%' as c) ->
    Buf_read.char c buf_read;
    Buffer.add_char buf c;
    Buffer.add_char buf @@ hex_dig buf_read;
    Buffer.add_char buf @@ hex_dig buf_read;
    `Ok
  | Some _ | None -> `End

let rec segment buf buf_read =
  match pchar buf buf_read with
  | `Ok -> segment buf buf_read
  | `End -> Buffer.contents buf

let absolute_path buf_read =
  let buf = Buffer.create 10 in
  let rec loop () =
    match Buf_read.peek_char buf_read with
    | Some '/' ->
      Buf_read.char '/' buf_read;
      let seg = segment buf buf_read in
      Buffer.clear buf;
      seg :: loop ()
    | Some _ | None -> []
  in
  loop ()

(* [query         = *( pchar / "/" / "?" )] *)
(* let query buf_read = buf_read *)
