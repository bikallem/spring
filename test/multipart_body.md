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

## Multipart_body.next_part

```ocaml
# let p = Multipart_body.next_part t;;
val p : Multipart_body.part = <abstr>

# Multipart_body.file_name p ;;
- : string option = None

# Multipart_body.form_name p ;;
- : string option = Some "submit-name"

# Multipart_body.headers p |> (Eio.traceln "%a" Header.pp) ;;
+{
+  content-disposition:  form-data; name="submit-name"
+}
- : unit = ()

# let flow = Multipart_body.flow p;;
val flow : Eio.Flow.source = <obj>

# let r = Eio.Buf_read.of_flow ~max_size:max_int flow ;;
val r : Eio.Buf_read.t = <abstr>

# Eio.Buf_read.take_all  r;;
- : string = "Larry"

# Eio.Flow.single_read flow (Cstruct.create 10) ;;
Exception: End_of_file.

# let p2 = Multipart_body.next_part t;;
val p2 : Multipart_body.part = <abstr>

# Multipart_body.file_name p2;;
- : string option = Some "file1.txt"

# Multipart_body.form_name p2;;
- : string option = Some "files"

# let flow2 = Multipart_body.flow p2;;
val flow2 : Eio.Flow.source = <obj>

# let r = Eio.Buf_read.of_flow ~max_size:max_int flow2;;
val r : Eio.Buf_read.t = <abstr>

# Eio.Buf_read.take_all r;;
- : string = "... contents of file1.txt ..."

# Eio.Flow.single_read flow2 (Cstruct.create 10) ;;
Exception: End_of_file.

# Multipart_body.next_part t;;
Exception: End_of_file.
```

