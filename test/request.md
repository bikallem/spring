# Request

```ocaml
open Spring
```

A `Buffer.t` sink to test `Body.writer`.

```ocaml
let test_client r =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    Request.write_client_request r bw;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

### parse_server_request

Mock the client addr.

```ocaml
let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)

let make_buf_read version meth connection = 
  let s = Printf.sprintf "%s /products HTTP/%s\r\nHost: www.example.com\r\nConnection: %s\r\nTE: trailers\r\nUser-Agent: cohttp-eio\r\n\r\n" meth version connection in
  Eio.Buf_read.of_string s
```

#### Parse HTTP/1.1 GET request. Keep-alive should be `true`.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.1" "get" "TE";;
val r : Request.server Request.t = <abstr>

# Request.keep_alive r ;;
- : bool = true

# Eio.traceln "%a" Headers.pp @@ Request.headers r;;
+[
+  Host: www.example.com;
+  Connection: TE;
+  Te: trailers;
+  User-Agent: cohttp-eio
+]
- : unit = ()
```

#### Parse HTTP/1.1 GET request. Keep-alive should be `true`.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.1" "get" "keep-alive, TE";;
val r : Request.server Request.t = <abstr>

# Eio.traceln "%a" Headers.pp @@ Request.headers r;;
+[
+  Host: www.example.com;
+  Connection: keep-alive, TE;
+  Te: trailers;
+  User-Agent: cohttp-eio
+]
- : unit = ()

# Request.keep_alive r ;;
- : bool = true
```

#### Parse HTTP/1.1 GET request. Keep-alive should be `false`.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.1" "get" "close, TE";;
val r : Request.server Request.t = <abstr>

# Eio.traceln "%a" Headers.pp @@ Request.headers r;;
+[
+  Host: www.example.com;
+  Connection: close, TE;
+  Te: trailers;
+  User-Agent: cohttp-eio
+]
- : unit = ()

# Request.keep_alive r ;;
- : bool = false
```
#### Parse HTTP/1.0 GET request. Keep-alive should be `false`.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.0" "get" "TE" ;;
val r : Request.server Request.t = <abstr>

# Eio.traceln "%a" Headers.pp @@ Request.headers r;;
+[
+  Host: www.example.com;
+  Connection: TE;
+  Te: trailers;
+  User-Agent: cohttp-eio
+]
- : unit = ()

# Request.keep_alive r ;;
- : bool = false
```

#### Parse HTTP/1.0 GET request. Keep-alive should be `false`.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.0" "get" "close, TE" ;;
val r : Request.server Request.t = <abstr>

# Eio.traceln "%a" Headers.pp @@ Request.headers r;;
+[
+  Host: www.example.com;
+  Connection: close, TE;
+  Te: trailers;
+  User-Agent: cohttp-eio
+]
- : unit = ()

# Request.keep_alive r ;;
- : bool = false
```
#### Parse HTTP/1.0 GET request. Keep-alive should be `true`.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.0" "get" "keep-alive, TE" ;;
val r : Request.server Request.t = <abstr>

# Eio.traceln "%a" Headers.pp @@ Request.headers r;;
+[
+  Host: www.example.com;
+  Connection: keep-alive, TE;
+  Te: trailers;
+  User-Agent: cohttp-eio
+]
- : unit = ()

# Request.keep_alive r ;;
- : bool = true
```

#### Parse request methods - Head, Delete, Options, Trace, Connect, Post, Put and Patch - correctly.

```ocaml
let parse_method m = 
  let r = Request.parse_server_request client_addr @@ make_buf_read "1.1" m "TE" in
  Request.meth r
```

```ocaml
# parse_method "head" = Method.head ;;
- : bool = true

# parse_method "delete" = Method.delete ;;
- : bool = true

# parse_method "options" = Method.options ;;
- : bool = true

# parse_method "trace" = Method.trace ;;
- : bool = true

# parse_method "connect" = Method.connect ;;
- : bool = true

# parse_method "post" = Method.post ;;
- : bool = true

# parse_method "put" = Method.put ;;
- : bool = true

# parse_method "patch" = Method.patch ;;
- : bool = true
```

### pp

Pretty-print `client Request.t`.

```ocaml
# let headers = Headers.of_list ["Header1", "val 1"; "Header2", "val 2"] ;;
val headers : Headers.t = <abstr>

# let req = 
    Request.make_client_request
      ~version:Version.http1_1 
      ~headers 
      (Host.decode "www.example.com:8080") 
      ~resource:"/update" 
      Method.get 
      Body.none ;;
val req : Request.client Request.t = <abstr>

# Eio.traceln "%a" Request.pp req ;;
+{
+  Method: GET;
+  Resource: /update;
+  Version: HTTP/1.1;
+  Headers: [
+             Header1: val 1;
+             Header2: val 2
+           ];
+  Host: Domain www.example.com:8080
+}
- : unit = ()
```

Pretty-print `Request.server`.

```ocaml
# let headers = Headers.of_list ["Header1", "val 1"; "Header2", "val 2"] ;;
val headers : Headers.t = <abstr>
# let req = 
    Request.make_server_request
      ~version:Version.http1_1 
      ~headers 
      ~resource:"/update" 
      Method.get
      client_addr
      (Eio.Buf_read.of_string "")
       ;;
val req : Request.server Request.t = <abstr>

# Eio.traceln "%a" Request.pp req ;;
+{
+  Method: GET;
+  Resource: /update;
+  Version: HTTP/1.1;
+  Headers: [
+             Header1: val 1;
+             Header2: val 2
+           ];
+  Client Address: tcp:127.0.0.1:8081
+}
- : unit = ()
```

### find_cookie

```ocaml
# let headers = Headers.of_list ["Cookie", "SID=31d4d96e407aad42; lang=en"] ;;
val headers : Headers.t = <abstr>

# let req = 
    Request.make_server_request
      ~version:Version.http1_1 
      ~headers 
      ~resource:"/update" 
      Method.get
      client_addr
      (Eio.Buf_read.of_string "")
       ;;
val req : Request.server Request.t = <abstr>

# Request.find_cookie "SID" req;;
- : string option = Some "31d4d96e407aad42"

# Request.find_cookie "lang" req;;
- : string option = Some "en"

# Request.find_cookie "blah" req;;
- : string option = None
```

### add_cookie

```ocaml
# let req = 
    Request.make_client_request 
      ~version:Version.http1_1 
      (Host.decode "www.example.com:8080") 
      ~resource:"/update" 
      Method.get 
      Body.none ;;
val req : Request.client Request.t = <abstr>

# Request.find_cookie "lang" req;;
- : string option = None

# let req = Request.add_cookie ~name:"lang" ~value:"en" req ;;
val req : Request.client Request.t = <abstr>

# Request.find_cookie "lang" req;;
- : string option = Some "en"
```

### remove_cookie

```ocaml
# let headers = Headers.of_list ["Cookie", "SID=31d4d96e407aad42;lang=en"] ;;
val headers : Headers.t = <abstr>

# let req = 
    Request.make_client_request
      ~version:Version.http1_1 
      ~headers 
      (Host.decode "www.example.com:8080") 
      ~resource:"/update" 
      Method.get 
      Body.none ;;
val req : Request.client Request.t = <abstr>

# Request.find_cookie "lang" req;;
- : string option = Some "en"

# Request.find_cookie "SID" req;;
- : string option = Some "31d4d96e407aad42"

# let req = Request.remove_cookie "SID" req;;
val req : Request.client Request.t = <abstr>

# Request.find_cookie "SID" req;;
- : string option = None
```

### add_session_data/find_session_data

```ocaml
# let req =
    Request.make_server_request
      ~resource:"/update" 
      Method.get
      client_addr
      (Eio.Buf_read.of_string "");;
val req : Request.server Request.t = <abstr>

# Request.add_session_data ~name:"a" ~value:"a_val" req;;
- : unit = ()

# Request.find_session_data "a" req;;
- : string option = Some "a_val"
```

### make_server_request

`resource` parameter with empty string value is invalid.

```ocaml
# Request.make_server_request
    ~resource:"" 
    Method.get
    client_addr
    (Eio.Buf_read.of_string "");;
Exception: Invalid_argument "[resource] is an empty string".
```

### parse_server_request/find_session_data

Parse with session data initialized

```ocaml
let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let nonce = Cstruct.of_string "aaaaaaaaaaaa" 
let session = Session.cookie_codec key 
let session_data = 
  Session.Data.(
    add "a" "a_val" empty
    |> add "b" "b_val");;
let data : string = Session.encode ~nonce session_data session

let make_request_buf () : Eio.Buf_read.t = 
  let s = Printf.sprintf "GET /products HTTP/1.1\r\nHost: www.example.com\r\nCookie: %s=%s\r\nUser-Agent: cohttp-eio\r\n\r\n" (Session.cookie_name session) data in
  Eio.Buf_read.of_string s
```
```ocaml
# let r = Request.parse_server_request ~session client_addr @@ make_request_buf () ;;
val r : Request.server Request.t = <abstr>

# Request.find_session_data "a" r;;
- : string option = Some "a_val"

# Request.find_session_data "b" r;;
- : string option = Some "b_val"
```
