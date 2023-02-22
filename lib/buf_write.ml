include Eio.Buf_write

let write_header w (k : Header.lname) v =
  let k = (k :> string) in
  string w k;
  string w ": ";
  string w v;
  string w "\r\n"

let write_headers w headers =
  let headers = Header.clean_dup headers in
  Header.iter (write_header w) headers
