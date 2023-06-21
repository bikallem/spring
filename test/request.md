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
    Request.Client.write r bw;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

## Request.Server.parse

Mock the client addr.

```ocaml
let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)

let make_buf_read version meth connection = 
  let s = Printf.sprintf "%s /products HTTP/%s\r\nHost: www.example.com\r\nConnection: %s\r\nTE: trailers\r\nUser-Agent: cohttp-eio\r\n\r\n" meth version connection in
  Eio.Buf_read.of_string s
```

### Parse HTTP/1.1 GET request. Keep-alive should be `true`.

```ocaml
# let r = Request.Server.parse client_addr @@ make_buf_read "1.1" "get" "TE";;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 1); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Request.Server.keep_alive r ;;
- : bool = true

# Eio.traceln "%a" Header.pp r.headers;;
+{
+  Host:  www.example.com;
+  Connection:  TE;
+  Te:  trailers;
+  User-Agent:  cohttp-eio
+}
- : unit = ()
```

### Parse HTTP/1.1 GET request. Keep-alive should be `true`.

```ocaml
# let r = Request.Server.parse client_addr @@ make_buf_read "1.1" "get" "keep-alive, TE";;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 1); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Eio.traceln "%a" Header.pp r.headers;;
+{
+  Host:  www.example.com;
+  Connection:  keep-alive, TE;
+  Te:  trailers;
+  User-Agent:  cohttp-eio
+}
- : unit = ()

# Request.Server.keep_alive r ;;
- : bool = true
```

### Parse HTTP/1.1 GET request. Keep-alive should be `false`.

```ocaml
# let r = Request.Server.parse client_addr @@ make_buf_read "1.1" "get" "close, TE";;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 1); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Eio.traceln "%a" Header.pp r.headers;;
+{
+  Host:  www.example.com;
+  Connection:  close, TE;
+  Te:  trailers;
+  User-Agent:  cohttp-eio
+}
- : unit = ()

# Request.Server.keep_alive r ;;
- : bool = false
```
### Parse HTTP/1.0 GET request. Keep-alive should be `false`.

```ocaml
# let r = Request.Server.parse client_addr @@ make_buf_read "1.0" "get" "TE" ;;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 0); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Eio.traceln "%a" Header.pp r.headers;;
+{
+  Host:  www.example.com;
+  Connection:  TE;
+  Te:  trailers;
+  User-Agent:  cohttp-eio
+}
- : unit = ()

# Request.Server.keep_alive r ;;
- : bool = false
```

### Parse HTTP/1.0 GET request. Keep-alive should be `false`.

```ocaml
# let r = Request.Server.parse client_addr @@ make_buf_read "1.0" "get" "close, TE" ;;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 0); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Eio.traceln "%a" Header.pp r.headers ;;
+{
+  Host:  www.example.com;
+  Connection:  close, TE;
+  Te:  trailers;
+  User-Agent:  cohttp-eio
+}
- : unit = ()

# Request.Server.keep_alive r ;;
- : bool = false
```
### Parse HTTP/1.0 GET request. Keep-alive should be `true`.

```ocaml
# let r = Request.Server.parse client_addr @@ make_buf_read "1.0" "get" "keep-alive, TE" ;;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 0); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Eio.traceln "%a" Header.pp r.headers ;;
+{
+  Host:  www.example.com;
+  Connection:  keep-alive, TE;
+  Te:  trailers;
+  User-Agent:  cohttp-eio
+}
- : unit = ()

# Request.Server.keep_alive r ;;
- : bool = true
```

### Parse request methods - Head, Delete, Options, Trace, Connect, Post, Put and Patch - correctly.

```ocaml
let parse_method m = 
  let r = Request.parse client_addr @@ make_buf_read "1.1" m "TE" in
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

## Request.pp

Pretty-print `Request.Client.t`.

```ocaml
# let headers = Header.of_list ["Header1", "val 1"; "Header2", "val 2"] ;;
val headers : Header.t = <abstr>
# let req = 
    Request.Client.make
      ~version:Version.http1_1 
      ~headers 
      ~port:8080 
      ~host:"www.example.com" 
      ~resource:"/update" 
      Method.get 
      Body.none ;;
val req : Request.Client.t =
  {Spring.Request.Client.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>; host = "www.example.com";
   port = Some 8080;
   body = {Spring__.Body.write_body = <fun>; write_headers = <fun>}}

# Request.Client.pp Format.std_formatter req ;;
{
  Version:  HTTP/1.1;
  Method:  get;
  URI:  /update;
  Headers :
    {
      Header1:  val 1;
      Header2:  val 2
    };
  Host:  www.example.com:8080
}
- : unit = ()
```

Pretty-print `Request.server`.

```ocaml
# let headers = Header.of_list ["Header1", "val 1"; "Header2", "val 2"] ;;
val headers : Header.t = <abstr>
# let req = 
    Request.server_request
      ~version:Version.http1_1 
      ~headers 
      ~resource:"/update" 
      Method.get
      client_addr
      (Eio.Buf_read.of_string "")
       ;;
val req : Request.server_request = <obj>

# Request.pp Format.std_formatter req ;;
{
  Version:  HTTP/1.1;
  Method:  get;
  URI:  /update;
  Headers :
    {
      Header1:  val 1;
      Header2:  val 2
    };
  Client Address:  tcp:127.0.0.1:8081
}
- : unit = ()
```

## Request.Server.find_cookie

```ocaml
# let headers = Header.of_list ["Cookie", "SID=31d4d96e407aad42; lang=en"] ;;
val headers : Header.t = <abstr>

# let req = 
    Request.Server.make
      ~version:Version.http1_1 
      ~headers 
      ~resource:"/update" 
      Method.get
      client_addr
      (Eio.Buf_read.of_string "")
       ;;
val req : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Request.Server.find_cookie "SID" req;;
- : string option = Some "31d4d96e407aad42"

# Request.Server.find_cookie "lang" req;;
- : string option = Some "en"

# Request.Server.find_cookie "blah" req;;
- : string option = None
```

## Request.Client.add_cookie

```ocaml
# let req = 
    Request.Client.make 
      ~version:Version.http1_1 
      ~port:8080 
      ~host:"www.example.com" 
      ~resource:"/update" 
      Method.get 
      Body.none ;;
val req : Request.Client.t =
  {Spring.Request.Client.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>; host = "www.example.com";
   port = Some 8080;
   body = {Spring__.Body.write_body = <fun>; write_headers = <fun>}}

# Request.Client.find_cookie "lang" req;;
- : string option = None

# let req = Request.Client.add_cookie ~name:"lang" ~value:"en" req ;;
val req : Request.Client.t =
  {Spring.Request.Client.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>; host = "www.example.com";
   port = Some 8080;
   body = {Spring__.Body.write_body = <fun>; write_headers = <fun>}}

# Request.Client.find_cookie "lang" req;;
- : string option = Some "en"
```

## Request.Client.remove_cookie

```ocaml
# let headers = Header.of_list ["Cookie", "SID=31d4d96e407aad42;lang=en"] ;;
val headers : Header.t = <abstr>

# let req = 
    Request.Client.make
      ~version:Version.http1_1 
      ~headers 
      ~port:8080 
      ~host:"www.example.com" 
      ~resource:"/update" 
      Method.get 
      Body.none ;;
val req : Request.Client.t =
  {Spring.Request.Client.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>; host = "www.example.com";
   port = Some 8080;
   body = {Spring__.Body.write_body = <fun>; write_headers = <fun>}}

# Request.Client.find_cookie "lang" req;;
- : string option = Some "en"

# Request.Client.find_cookie "SID" req;;
- : string option = Some "31d4d96e407aad42"

# let req = Request.Client.remove_cookie "SID" req;;
val req : Request.Client.t =
  {Spring.Request.Client.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>; host = "www.example.com";
   port = Some 8080;
   body = {Spring__.Body.write_body = <fun>; write_headers = <fun>}}

# Request.Client.find_cookie "SID" req;;
- : string option = None
```

## Request.Server.add_session_data/find_session_data

```ocaml
# let req =
    Request.Server.make
      ~resource:"/update" 
      Method.get
      client_addr
      (Eio.Buf_read.of_string "");;
val req : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/update";
   version = (1, 1); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = None}

# Request.Server.add_session_data ~name:"a" ~value:"a_val" req;;
- : unit = ()

# Request.Server.find_session_data "a" req;;
- : string option = Some "a_val"
```

## Request.Server.parse/find_session_data

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
  let s = Printf.sprintf "GET /products HTTP/1.1\r\nHost: www.example.com\r\nCookie: %s=%s\r\nUser-Agent: cohttp-eio\r\n\r\n" session#cookie_name data in
  Eio.Buf_read.of_string s
```
```ocaml
# let r = Request.Server.parse ~session client_addr @@ make_request_buf () ;;
val r : Request.Server.t =
  {Spring.Request.Server.meth = "get"; resource = "/products";
   version = (1, 1); headers = <abstr>;
   client_addr = `Tcp ("\127\000\000\001", 8081); buf_read = <abstr>;
   session_data = Some <abstr>}

# Request.Server.find_session_data "a" r;;
- : string option = Some "a_val"

# Request.Server.find_session_data "b" r;;
- : string option = Some "b_val"
```
