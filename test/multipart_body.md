# Multipart tests

```ocaml
open Spring

let body content_type_hdr txt = object
  method headers = Header.of_list ["content-type", content_type_hdr]
  method buf_read = Eio.Buf_read.of_string txt
end ;;
```

## Multipart_body.make

```ocaml
# let body_txt1 ="--AaB03x\r\nContent-Disposition: form-data; name=\"submit-name\"\r\n\r\nLarry\r\n--AaB03x\r\nContent-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\r\nContent-Type: text/plain\r\n\r\n... contents of file1.txt ...\r\n--AaB03x--\r\n";;
val body_txt1 : string =
  "--AaB03x\r\nContent-Disposition: form-data; name=\"submit-name\"\r\n\r\nLarry\r\n--AaB03x\r\nContent-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\r\nContent-Type: text/plain\r\n\r\n... contents of file1.txt ...\r\n--AaB03x--\r\n"

# let t = Multipart_body.make (body "multipart/form-data" body_txt1);;
Exception: Invalid_argument "body: boundary value not found".

# let t = Multipart_body.make (body "multipart/form-data; boundary=AaB03x" body_txt1);;
val t : Multipart_body.t = <abstr>
```

## Multipart_body.boundary

```ocaml
# Multipart_body.boundary t;; 
- : string = "AaB03x"
```
