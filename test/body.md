# Body 

```ocaml
open Spring 
```

A `Buffer.t` sink to test `Body.writer`.

```ocaml
let test_writer (body: Body.writable) =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    Body.write_headers bw body;
    Body.write_body bw body;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

## writable_content

```ocaml
# let content_type = Content_type.make ("text", "plain");;
val content_type : Content_type.t = <abstr>

# test_writer @@ Body.writable_content content_type "hello world";;
+Content-Length: 11
+Content-Type: text/plain
+hello world
- : unit = ()
```

## writable_form_values

```ocaml
# test_writer @@ Body.writable_form_values ["name1", "val a"; "name1", "val b"; "name1", "val c"; "name2", "val c"; "name2", "val d"; "name2", "val e"] ;;
+Content-Length: 83
+Content-Type: application/x-www-form-urlencoded
+name1=val%20a&name1=val%20b&name1=val%20c&name2=val%20c&name2=val%20d&name2=val%20e
- : unit = ()
```

## read_content

```ocaml
let test_reader body headers f =
  Eio_main.run @@ fun env ->
    let buf_read = Eio.Buf_read.of_string body in
    let headers = Headers.of_list headers in
    let r = Body.make_readable headers buf_read in
    f r;;
```

`read_content` reads the contents of a reader if `headers` contains valid `Content-Length` header.

```ocaml
# test_reader "hello world" ["Content-Length","11"] Body.read_content ;;
- : string option = Some "hello world"
```

None if 'Content-Length' is not valid.

```ocaml
# test_reader "hello world" ["Content-Length","12a"] Body.read_content ;;
- : string option = None
```

Or if it is missing.

```ocaml
# test_reader "hello world" [] Body.read_content ;;
- : string option = None
```

## read_form_values 

The reader below has both "Content-Length" and "Content-Type" header set correctly, so we are able
to parse the body correctly.

```ocaml
# let body = "name1=val%20a&name1=val%20b&name1=val%20c&name2=val%20c&name2=val%20d&name2=val%20e" in
  test_reader
    body
    [("Content-Length", (string_of_int (String.length body))); ("Content-Type", "application/x-www-form-urlencoded")]
    Body.read_form_values ;;
- : (string * string) list =
[("name1", "val a"); ("name1", "val b"); ("name1", "val c");
 ("name2", "val c"); ("name2", "val d"); ("name2", "val e")]
```

Note that the reader below doesn't have "Content-Type" header. Thus `read_form_values` returns am empty list.

```ocaml
# let body = "name1=val%20a&name1=val%20b&name1=val%20c&name2=val%20c&name2=val%20d&name2=val%20e" in
  test_reader
    body
    [("Content-Length", (string_of_int (String.length body)))]
    Body.read_form_values ;;
- : (string * string) list = []
```

Note that the reader below doesn't have "Content-Length" header. Thus `read_form_values` returns am empty list.

```ocaml
# let body = "name1=val%20a,val%20b,val%20c&name2=val%20c,val%20d,val%20e" in
  test_reader
    body
    [("Content-Type", "application/x-www-form-urlencoded")]
    Body.read_form_values ;;
- : (string * string) list = []
```
