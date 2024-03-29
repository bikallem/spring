# Chunked

```ocaml
open Spring
```

A `Buffer.t` sink to test `Body.writer`.

```ocaml
let test_writer (body : Body.writable) =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
     Body.write_headers bw body;
     Body.write_body bw body;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

## Chunked.writable

Writes both chunked body and trailer since `ua_supports_trailer:true`.

```ocaml
# let write_chunk f =
    f @@ Chunked.make ~extensions:["ext1",Some "ext1_v"] "Hello, ";
    Eio.Fiber.yield ();
    Eio.traceln "Resuming ...";
    f @@ Chunked.make ~extensions:["ext2",None] "world!";
    Eio.Fiber.yield ();
    Eio.traceln "Resuming ...";
    f @@ Chunked.make "Again!";
    f @@ Chunked.make "";;
val write_chunk : (Chunked.t -> 'a) -> 'a = <fun>
# let write_trailer f =
    let trailer_headers =
      Headers.of_list
        [
          ("Expires", "Wed, 21 Oct 2015 07:28:00 GMT");
          ("Header1", "Header1 value text");
          ("Header2", "Header2 value text");
        ]
    in
    f trailer_headers;;
val write_trailer : (Headers.t -> 'a) -> 'a = <fun>

# test_writer (Chunked.writable ~ua_supports_trailer:true write_chunk write_trailer) ;;
+Resuming ...
+Resuming ...
+Transfer-Encoding: chunked
+7;ext1=ext1_v
+Hello, 
+6;ext2
+world!
+6
+Again!
+0
+Expires: Wed, 21 Oct 2015 07:28:00 GMT
+Header1: Header1 value text
+Header2: Header2 value text
+
+
- : unit = ()
```

Writes only chunked body and not the trailers since `ua_supports_trailer:false`.

```ocaml
# test_writer (Chunked.writable ~ua_supports_trailer:false write_chunk write_trailer) ;;
+Resuming ...
+Resuming ...
+Transfer-Encoding: chunked
+7;ext1=ext1_v
+Hello, 
+6;ext2
+world!
+6
+Again!
+0
+
+
- : unit = ()
```

## Chunked.reader

```ocaml
let test_reader body headers f =
  Eio_main.run @@ fun env ->
    let buf_read = Eio.Buf_read.of_string body in
    let headers = Headers.of_list headers in
    let r = Body.make_readable headers buf_read in
    f r

let f chunk = Eio.traceln "%a" Chunked.pp chunk

let body = "7;ext1=ext1_v;ext2=ext2_v;ext3\r\nMozilla\r\n9\r\nDeveloper\r\n7\r\nNetwork\r\n0\r\nHeader2: Header2 value text\r\nHeader1: Header1 value text\r\nExpires: Wed, 21 Oct 2015 07:28:00 GMT\r\n\r\n"
```

The test below prints chunks to a standard output and returns trailer headers. Note, we don't return `Header2` 
because the `Trailer` header in request doesn't specify Header2 as being included in the chunked encoding trailer
header list.

```ocaml
# let headers = 
    test_reader
      body
      ["Trailer", "Expires, Header1"; "Transfer-Encoding", "chunked"]
      (Chunked.read_chunked f);;
+
+[size = 7; ext1="ext1_v" ext2="ext2_v" ext3
+Mozilla
+]
+
+[size = 9
+Developer
+]
+
+[size = 7
+Network
+]
+
+[size = 0 ]
val headers : Headers.t option = Some <abstr>

# Eio.traceln "%a" Headers.pp (Option.get headers) ;;
+[
+  Content-Length: 23;
+  Header1: Header1 value text
+]
- : unit = ()
```

Returns `Header2` since it is specified in the request `Trailer` header.

```ocaml
# let headers = 
    test_reader
      body
      ["Trailer", "Expires, Header1, Header2"; "Transfer-Encoding", "chunked"]
      (Chunked.read_chunked f);;
+
+[size = 7; ext1="ext1_v" ext2="ext2_v" ext3
+Mozilla
+]
+
+[size = 9
+Developer
+]
+
+[size = 7
+Network
+]
+
+[size = 0 ]
val headers : Headers.t option = Some <abstr>

# Eio.traceln "%a" Headers.pp (Option.get headers) ;;
+[
+  Content-Length: 23;
+  Header2: Header2 value text;
+  Header1: Header1 value text
+]
- : unit = ()
```

Nothing is read if `Transfer-Encoding: chunked` header is missing.

```ocaml
# let headers = 
    test_reader
      body
      ["Trailer", "Expires, Header1, Header2"; "Transfer-Encoding", "gzip"]
      (Chunked.read_chunked f);;
val headers : Headers.t option = None

# headers = None;;
- : bool = true
```

reader works okay even if there are no trailers.

```ocaml
let body = "7;ext1=ext1_v;ext2=ext2_v;ext3\r\nMozilla\r\n9\r\nDeveloper\r\n7\r\nNetwork\r\n0\r\n\r\n"
```

```ocaml
# let headers = 
    test_reader
      body
      ["Trailer", "Expires, Header1, Header2"; "Transfer-Encoding", "chunked"]
      (Chunked.read_chunked f);;
+
+[size = 7; ext1="ext1_v" ext2="ext2_v" ext3
+Mozilla
+]
+
+[size = 9
+Developer
+]
+
+[size = 7
+Network
+]
+
+[size = 0 ]
val headers : Headers.t option = Some <abstr>

# headers = None;;
- : bool = false
```

