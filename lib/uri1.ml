type segment = string

let hex_dig t : char =
  match Buf_read.any_char t with
  | ('0' .. '9' | 'A' .. 'F') as c -> c
  | c -> Fmt.failwith "expected HEXDIG but got '%c'" c

let segment t : string =
  let buf = Buffer.create 10 in
  let rec loop () =
    match Buf_read.peek_char t with
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
      Buf_read.char c t;
      Buffer.add_char buf c;
      loop ()
    | Some ('%' as c) ->
      Buf_read.char c t;
      Buffer.add_char buf c;
      Buffer.add_char buf @@ hex_dig t;
      Buffer.add_char buf @@ hex_dig t;
      loop ()
    | _ -> Buffer.contents buf
  in
  loop ()

let rec absolute_path buf_read =
  match Buf_read.peek_char buf_read with
  | Some '/' ->
    Buf_read.char '/' buf_read;
    let seg = segment buf_read in
    seg :: absolute_path buf_read
  | Some _ | None -> []
