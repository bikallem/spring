# Response

```ocaml
open Spring 
```

## Response.parse_client_response

```ocaml
let make_buf_read () =
  Eio.Buf_read.of_string @@
    "HTTP/1.1 200 OK\r\n" ^
    "content-length: 13\r\n" ^
    "date: Wed, 08 Feb 2023 16:18:17 GMT\r\n" ^
    "content-type: text/html; charset=utf-8\r\n" ^
    "x-powered-by: Express\r\n" ^
    "cache-control: public, max-age=86400\r\n" ^
    "cf-cache-status: DYNAMIC\r\n" ^
    "server: cloudflare\r\n" ^
    "cf-ray: 7965ae27fa7c75bf-LHR\r\n" ^
    "content-encoding: br\r\n" ^
    "X-Firefox-Spdy: h2\r\n" ^
    "\r\n" ^
    "hello, world!"
    ;;
```

```ocaml
# let res = Response.parse_client_response @@ make_buf_read () ;;
val res : Response.client Response.t = <abstr>

# Eio.traceln "%a" Headers.pp @@ Response.headers res ;;
+{
+  Content-Length:  13;
+  Date:  Wed, 08 Feb 2023 16:18:17 GMT;
+  Content-Type:  text/html; charset=utf-8;
+  X-Powered-By:  Express;
+  Cache-Control:  public, max-age=86400;
+  Cf-Cache-Status:  DYNAMIC;
+  Server:  cloudflare;
+  Cf-Ray:  7965ae27fa7c75bf-LHR;
+  Content-Encoding:  br;
+  X-Firefox-Spdy:  h2
+}
- : unit = ()
```

## server_response

A `Buffer.t` sink to test `Body.writer`.

```ocaml
let test_server_response r =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    Response.write_server_response bw r;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

## Response.text

```ocaml
# test_server_response @@ Response.text "hello, world";;
+HTTP/1.1 200 OK
+Content-Length: 12
+Content-Type: text/plain; charset=uf-8
+
+hello, world
- : unit = ()
```

## Response.html

```ocaml
# test_server_response @@ Response.html "hello, world";;
+HTTP/1.1 200 OK
+Content-Length: 12
+Content-Type: text/html; charset=uf-8
+
+hello, world
- : unit = ()
```

## Response.not_found

```ocaml
# test_server_response @@ Response.not_found ;;
+HTTP/1.1 404 Not Found
+Content-Length: 0
+
+
- : unit = ()
```

## Response.internal_server_error

```ocaml
# test_server_response @@ Response.internal_server_error ;;
+HTTP/1.1 500 Internal Server Error
+Content-Length: 0
+
+
- : unit = ()
```

## Response.bad_request

```ocaml
# test_server_response @@ Response.bad_request ;;
+HTTP/1.1 400 Bad Request
+Content-Length: 0
+
+
- : unit = ()
```

## Response.chunked_response

```ocaml
# let write_chunk f =
    f @@ Chunked.make ~extensions:["ext1",Some "ext1_v"] "Hello, ";
    f @@ Chunked.make ~extensions:["ext2",None] "world!";
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
```

Writes chunked response trailer headers.

```ocaml
# test_server_response @@ Response.chunked_response ~ua_supports_trailer:true write_chunk write_trailer ;;
+HTTP/1.1 200 OK
+Transfer-Encoding: chunked
+
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

No chunked trailer headers.

```ocaml
# test_server_response @@ Response.chunked_response ~ua_supports_trailer:false write_chunk write_trailer ;;
+HTTP/1.1 200 OK
+Transfer-Encoding: chunked
+
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

## Response.add_set_cookie

```ocaml
# let txt_response = Response.html "hello, world" ;;
val txt_response : Response.server Response.t = <abstr>
```

```ocaml
# let id_cookie = Set_cookie.make ("ID", "1234") ;;
val id_cookie : Set_cookie.t = <abstr>

# let res = Response.add_set_cookie id_cookie txt_response ;;
val res : Response.server Response.t = <abstr>

# test_server_response res;;
+HTTP/1.1 200 OK
+Content-Length: 12
+Content-Type: text/html; charset=uf-8
+Set-Cookie: ID=1234; Secure; HttpOnly
+
+hello, world
- : unit = ()
```

## Response.find_set_cookie

```ocaml
# Response.find_set_cookie "ID" res |> Option.iter (Eio.traceln "%a" Set_cookie.pp) ;;
+{
+  Name:  ID;
+  Value:  1234;
+  Secure;
+  HttpOnly
+}
- : unit = ()
```

## Response.remove_set_cookie

```ocaml
# let res = Response.remove_set_cookie "ID" res;;
val res : Response.server Response.t = <abstr>

# Response.find_set_cookie "ID" res ;;
- : Set_cookie.t option = None
```
