include Eio.Buf_write

let write_header w k v =
  string w k;
  string w ": ";
  string w v;
  string w "\r\n"

let write_headers w headers =
  let headers = Header.clean_dup headers in
  Header.iter (fun k v -> write_header w (k :> string) v) headers
