# Multipart tests

```ocaml
open Spring

let body content_type_hdr txt = 
  let headers = Header.of_list ["content-type", content_type_hdr] in
  let buf_read = Eio.Buf_read.of_string txt in
  Body.make_readable headers buf_read 
;;

let body_txt1 ="--AaB03x\r\nContent-Disposition: form-data; name=\"submit-name\"\r\n\r\nLarry\r\n--AaB03x\r\nContent-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\r\nContent-Type: text/plain\r\n\r\n... contents of file1.txt ...\r\n--AaB03x--"
```

## Multipart.reader

```ocaml
# let rdr = Multipart.reader (body "multipart/form-data" body_txt1);;
Exception: Invalid_argument "body: boundary value not found".

# let rdr = Multipart.reader (body "multipart/form-data; boundary=AaB03x" body_txt1);;
val rdr : Multipart.reader = <abstr>
```

## Multipart.boundary

```ocaml
# Multipart.boundary rdr;; 
- : string = "AaB03x"
```

## Multipart.next_part/read_all

```ocaml
# let p = Multipart.next_part rdr;;
val p : Multipart.reader Multipart.part = <abstr>

# Multipart.file_name p ;;
- : string option = None

# Multipart.form_name p ;;
- : string = "submit-name"

# Multipart.headers p |> (Eio.traceln "%a" Header.pp) ;;
+{
+  Content-Disposition:  form-data; name="submit-name"
+}
- : unit = ()

# Multipart.read_all p;;
- : string = "Larry"

# Eio.Flow.single_read (Multipart.as_flow p) (Cstruct.create 10) ;;
Exception: End_of_file.

# let p2 = Multipart.next_part rdr;;
val p2 : Multipart.reader Multipart.part = <abstr>

# Multipart.file_name p2;;
- : string option = Some "file1.txt"

# Multipart.form_name p2;;
- : string = "files"

# Multipart.read_all p2;;
- : string = "... contents of file1.txt ..."

# Multipart.read_all p2;;
- : string = ""

# Eio.Flow.single_read (Multipart.as_flow p2) (Cstruct.create 10) ;;
Exception: End_of_file.

# Multipart.next_part rdr;;
Exception: End_of_file.
```

## Multipart.form

```ocaml
# let form = Multipart.form (body "multipart/form-data; boundary=AaB03x" body_txt1);;
val form : Multipart.form = <abstr>

# Multipart.find_value_field "submit-name" form ;;
- : string option = Some "Larry"

# let form_field1 = Multipart.find_file_field "files" form |> Option.get ;;
val form_field1 : Multipart.file_field = <abstr>

# Multipart.file_name form_field1 ;;
- : string option = Some "file1.txt"

# Multipart.file_content form_field1;;
- : string = "... contents of file1.txt ..."

# Eio.traceln "%a" Header.pp @@ Multipart.headers form_field1;;
+{
+  Content-Disposition:  form-data; name="files"; filename="file1.txt";
+  Content-Type:  text/plain
+}
- : unit = ()
```

## Multipart.writable

A `Buffer.t` sink to test `Body.writer`.

```ocaml
let test_writable f =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  let body = f () in
  Eio.Buf_write.with_flow s (fun bw ->
    Body.write_headers bw body;
    Eio.Buf_write.string bw "\r\n";
    Body.write_body bw body;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

Writable with 2 parts.

```ocaml
# let p1 = Multipart.writable_file_part ~filename:"a.txt" ~form_name:"file" (Eio.Flow.string_source "content of a.txt");;
val p1 : Multipart.writable Multipart.part = <abstr>

# let p2 = Multipart.writable_value_part ~form_name:"detail" ~value:"file is a text file.";;
val p2 : Multipart.writable Multipart.part = <abstr>

# test_writable @@ fun () -> Multipart.writable ~boundary:"--A1B2C3" [p1;p2];;
+Content-Length: 190
+Content-Type: multipart/formdata; boundary=--A1B2C3
+
+----A1B2C3
+Content-Disposition: form-data; filename="a.txt"; name="file"
+
+content of a.txt
+----A1B2C3
+Content-Disposition: form-data; name="detail"
+
+file is a text file.
+----A1B2C3--
- : unit = ()
```

Writable with only one part. 

```ocaml
# let p1 = Multipart.writable_file_part ~filename:"a.txt" ~form_name:"file" (Eio.Flow.string_source "content of a.txt");;
val p1 : Multipart.writable Multipart.part = <abstr>

# test_writable @@ fun () -> Multipart.writable ~boundary:"--A1B2C3" [p1];;
+Content-Length: 107
+Content-Type: multipart/formdata; boundary=--A1B2C3
+
+----A1B2C3
+Content-Disposition: form-data; filename="a.txt"; name="file"
+
+content of a.txt
+----A1B2C3--
- : unit = ()
```
