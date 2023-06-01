# Multipart tests

```ocaml
open Spring

let body content_type_hdr txt = object
  method headers = Header.of_list ["content-type", content_type_hdr]
  method buf_read = Eio.Buf_read.of_string txt
end ;;
```

## Multipart.reader

```ocaml
# let body_txt1 ="--AaB03x\r\nContent-Disposition: form-data; name=\"submit-name\"\r\n\r\nLarry\r\n--AaB03x\r\nContent-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\r\nContent-Type: text/plain\r\n\r\n... contents of file1.txt ...\r\n--AaB03x--\r\n";;
val body_txt1 : string =
  "--AaB03x\r\nContent-Disposition: form-data; name=\"submit-name\"\r\n\r\nLarry\r\n--AaB03x\r\nContent-Disposition: form-data; name=\"files\"; filename=\"file1.txt\"\r\nContent-Type: text/plain\r\n\r\n... contents of file1.txt ...\r\n--AaB03x--\r\n"

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

## Multipart.next_part

```ocaml
# let p = Multipart.next_part rdr;;
val p : Multipart.reader Multipart.part = <abstr>

# Multipart.file_name p ;;
- : string option = None

# Multipart.form_name p ;;
- : string option = Some "submit-name"

# Multipart.headers p |> (Eio.traceln "%a" Header.pp) ;;
+{
+  Content-Disposition:  form-data; name="submit-name"
+}
- : unit = ()

# let flow = Multipart.reader_flow p;;
val flow : Eio.Flow.source = <obj>

# let r = Eio.Buf_read.of_flow ~max_size:max_int flow ;;
val r : Eio.Buf_read.t = <abstr>

# Eio.Buf_read.take_all  r;;
- : string = "Larry"

# Eio.Flow.single_read flow (Cstruct.create 10) ;;
Exception: End_of_file.

# let p2 = Multipart.next_part rdr;;
val p2 : Multipart.reader Multipart.part = <abstr>

# Multipart.file_name p2;;
- : string option = Some "file1.txt"

# Multipart.form_name p2;;
- : string option = Some "files"

# let flow2 = Multipart.reader_flow p2;;
val flow2 : Eio.Flow.source = <obj>

# let r = Eio.Buf_read.of_flow ~max_size:max_int flow2;;
val r : Eio.Buf_read.t = <abstr>

# Eio.Buf_read.take_all r;;
- : string = "... contents of file1.txt ..."

# Eio.Flow.single_read flow2 (Cstruct.create 10) ;;
Exception: End_of_file.

# Multipart.next_part rdr;;
Exception: End_of_file.
```

## Multipart.writable

A `Buffer.t` sink to test `Body.writer`.

```ocaml
let write_header b : < f : 'a. 'a Header.header -> 'a -> unit > =
  object
    method f : 'a. 'a Header.header -> 'a -> unit =
      fun hdr v ->
        let v = Header.encode hdr v in
        let name = (Header.name hdr :> string) in
        Header.write_header (Buffer.add_string b) name v
  end

let test_writer w =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    w#write_header (write_header b);
    w#write_body bw;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

Writable with 2 parts.

```ocaml
# let p1 = Multipart.make_part ~filename:"a.txt" (Eio.Flow.string_source "content of a.txt") "file";;
val p1 : Eio.Flow.source Multipart.part = <abstr>

# let p2 = Multipart.make_part (Eio.Flow.string_source "file is a text file.") "detail";;
val p2 : Eio.Flow.source Multipart.part = <abstr>

# let w = Multipart.writable "--A1B2C3" [p1;p2];;
val w : Body.writable = <obj>

# test_writer w;;
+Content-Length: 192
+Content-Type: multipart/formdata; boundary=--A1B2C3
+----A1B2C3
+Content-Disposition: form-data; filename="a.txt"; name="file"
+
+content of a.txt
+----A1B2C3
+Content-Disposition: form-data; name="detail"
+
+file is a text file.
+----A1B2C3--
+
- : unit = ()
```

Writable with only one part. 

```ocaml
# let p1 = Multipart.make_part ~filename:"a.txt" (Eio.Flow.string_source "content of a.txt") "file";;
val p1 : Eio.Flow.source Multipart.part = <abstr>

# let w = Multipart.writable "--A1B2C3" [p1];;
val w : Body.writable = <obj>

# test_writer w;;
+Content-Length: 109
+Content-Type: multipart/formdata; boundary=--A1B2C3
+----A1B2C3
+Content-Disposition: form-data; filename="a.txt"; name="file"
+
+content of a.txt
+----A1B2C3--
+
- : unit = ()
```
