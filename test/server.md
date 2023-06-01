# Server

```ocaml
open Spring 

let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)

let now = ref 1623940778.27033591

let fake_clock real_clock = object (_ : #Eio.Time.clock)
  method now = !now
  method sleep_until time =
    Eio.Time.sleep_until real_clock time;
    now := max !now time
end

let handler ctx =
  let req = Context.request ctx in
  match Request.resource req with
  | "/" -> Response.text "root"
  | "/upload" -> (
    match Body.read_content req with
    | Some a -> Response.text a
    | None -> Response.bad_request
    )
  | _ -> Response.not_found
```

## Server.run/Server.run_local

```ocaml
# Eio_main.run @@ fun env ->
  let server = Server.make ~on_error:raise (fake_clock env#clock) env#net handler in 
  Eio.Fiber.both 
    (fun () -> Server.run_local ~port:8081 server)
    (fun () ->
      Eio.Switch.run @@ fun sw ->
      let client = Client.make sw env#net in
      let res = Client.get client "localhost:8081" in
      Eio.traceln "Route: /";
      Eio.traceln "%a" Header.pp (Response.headers res);
      Eio.traceln "%s" (Body.read_content res |> Option.get);
      Eio.traceln "";
      Eio.traceln "Route: /upload";
      let body = 
        let content_type = Content_type.make ("text", "plain") in
        Body.content_writer content_type "hello world" 
      in
      let res = Client.post client body "localhost:8081/upload" in
      Eio.traceln "%a" Header.pp (Response.headers res);
      Eio.traceln "%s" (Body.read_content res |> Option.get);
      Server.shutdown server
    );;
+Route: /
+{
+  Content-Length:  4;
+  Content-Type:  text/plain; charset=uf-8
+}
+root
+
+Route: /upload
+{
+  Content-Length:  11;
+  Content-Type:  text/plain; charset=uf-8
+}
+hello world
- : unit = ()
```

## Server.pipeline  

A `router` pipeline is a simple `Request.resource` based request router. It only handles resource path "/" and delegates the rest to the builtin `Server.not_found_handler`. When a request is sent with "/" then we get a "hello, there" text response. However, if we try with any other resource path, we get `404 Not Found` response.

```ocaml
let router : Server.pipeline =
  fun next ctx ->
    let req = Context.request ctx in
    match Request.resource req with
    | "/" -> Response.text "hello, there"
    | _ -> next ctx

let final_handler : Server.handler = router @@ Server.not_found_handler
```

```ocaml
# Eio_main.run @@ fun env ->
  let server = Server.make ~on_error:raise (fake_clock env#clock) env#net final_handler in 
  Eio.Fiber.both 
    (fun () -> Server.run_local ~port:8081 server)
    (fun () ->
      Eio.Switch.run @@ fun sw ->
      let client = Client.make sw env#net in
      let res = Client.get client "localhost:8081" in
      Eio.traceln "Resource (/): %s" (Body.read_content res |> Option.get);
      let res = Client.get client "localhost:8081/products" in
      Eio.traceln "Resource (/products) : %a" Status.pp (Response.status res);
      Server.shutdown server
    );;
+Resource (/): hello, there
+Resource (/products) : 404 Not Found
- : unit = ()
```

## Server.host_header

```ocaml
let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)

let make_buf_read version meth connection = 
  let s = Printf.sprintf "%s /products HTTP/%s\r\nConnection: %s\r\nTE: trailers\r\nUser-Agent: cohttp-eio\r\n\r\n" meth version connection in
  Eio.Buf_read.of_string s

let hello _ctx = Response.text "hello"
```

Try with GET method.

```ocaml
# let r = Request.parse client_addr @@ make_buf_read "1.1" "get" "";;
val r : Request.server_request = <obj>

# let ctx = Context.make r;;
val ctx : Context.t = <abstr>

# let res1 = (Server.host_header @@ hello) ctx;;
val res1 : Response.server_response = <obj>

# Eio.traceln "%a" Response.pp res1 ;;
+{
+  Version:  HTTP/1.1;
+  Status:  400 Bad Request;
+  Headers :
+    {
+      Content-Length:  0
+    }
+}
- : unit = ()
```

Try with POST method.

```ocaml
# let r = Request.parse client_addr @@ make_buf_read "1.1" "post" "";;
val r : Request.server_request = <obj>

# let ctx = Context.make r;;
val ctx : Context.t = <abstr>

# let res1 = (Server.host_header @@ hello) ctx;;
val res1 : Response.server_response = <obj>

# Eio.traceln "%a" Response.pp res1 ;;
+{
+  Version:  HTTP/1.1;
+  Status:  400 Bad Request;
+  Headers :
+    {
+      Content-Length:  0
+    }
+}
- : unit = ()
```

A valid request with HOST header is processed okay.

```ocaml
# let buf_read = Printf.sprintf "%s /products HTTP/%s\r\nHost: www.example.com\r\nConnection: %s\r\nTE: trailers\r\nUser-Agent: cohttp-eio\r\n\r\n" "get" "1.1" ""
  |> Eio.Buf_read.of_string ;;
val buf_read : Eio.Buf_read.t = <abstr>

# let r = Request.parse client_addr buf_read;;
val r : Request.server_request = <obj>

# let ctx = Context.make r;;
val ctx : Context.t = <abstr>

# let res1 = (Server.host_header @@ hello) ctx;;
val res1 : Response.server_response = <obj>

# Eio.traceln "%a" Response.pp res1 ;;
+{
+  Version:  HTTP/1.1;
+  Status:  200 OK;
+  Headers :
+    { }
+}
- : unit = ()
```

## Server.response_date

```ocaml
let mock_clock = Eio_mock.Clock.make ()
let () = Eio_mock.Clock.set_time mock_clock 1666627935.85052109
```

A Date header is added to a 200 response.

```ocaml
# let hello _req = Response.text "hello, world!" ;;
val hello : 'a -> Response.server_response = <fun>

# let req = Request.server_request ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server_request = <obj>

# let ctx = Context.make req;;
val ctx : Context.t = <abstr>

# let h = Server.(response_date mock_clock) @@ hello ;;
val h : Server.handler = <fun>

# Eio.traceln "%a" Response.pp @@ h ctx;;
+{
+  Version:  HTTP/1.1;
+  Status:  200 OK;
+  Headers :
+    {
+      Date:  Mon, 24 Oct 2022 16:12:15 GMT
+    }
+}
- : unit = ()
```

A Date header is not added added to a 5xx status response. We use server_request `req` from above.

```ocaml
# let h _req = Response.server_response ~status:Status.internal_server_error Body.none ;;
val h : 'a -> Response.server_response = <fun>

# let h= Server.response_date mock_clock @@ h ;;
val h : Server.handler = <fun>

# Eio.traceln "%a" Response.pp @@ h ctx;;
+{
+  Version:  HTTP/1.1;
+  Status:  500 Internal Server Error;
+  Headers :
+    { }
+}
- : unit = ()
```

A Date header is not added added to a 1xx status response. We use server_request `req` from above.

```ocaml
# let h _req = Response.server_response ~status:Status.continue Body.none ;;
val h : 'a -> Response.server_response = <fun>

# let h= Server.response_date mock_clock @@ h ;;
val h : Server.handler = <fun>

# Eio.traceln "%a" Response.pp @@ h ctx;;
+{
+  Version:  HTTP/1.1;
+  Status:  100 Continue;
+  Headers :
+    { }
+}
- : unit = ()
```


## Server.strict_http

Check that "Host" header value is validated. See https://www.rfc-editor.org/rfc/rfc9112#section-3.2

```ocaml
# Eio_main.run @@ fun env ->
  let handler = Server.strict_http (fake_clock env#clock) @@ handler in
  let server = Server.make ~on_error:raise (fake_clock env#clock) env#net handler in 
  Eio.Fiber.both 
    (fun () -> Server.run_local ~port:8081 server)
    (fun () ->
      Eio.Net.with_tcp_connect ~host:"localhost" ~service:"8081" env#net @@ fun conn ->
      Eio.Flow.copy_string "GET / HTTP/1.1\r\n\r\n" conn;
      let buf = Cstruct.create 1024 in
      let got = Eio.Flow.single_read conn buf in
      Eio.traceln "%s" (Cstruct.to_string ~len:got buf);

      Eio.Flow.copy_string "GET / HTTP/1.1\r\nHost:example.com\r\nHost:example.com\r\n\r\n" conn;
      let got = Eio.Flow.single_read conn buf in
      Eio.traceln "%s" (Cstruct.to_string ~len:got buf);

      Eio.Flow.copy_string "GET / HTTP/1.1\r\nHost:example.com\r\n\r\n" conn;
      let got = Eio.Flow.single_read conn buf in
      Eio.traceln "%s" (Cstruct.to_string ~len:got buf);

      Eio.Flow.copy_string "GET / HTTP/1.1\r\nHost:192.168.1.16\r\n\r\n" conn;
      let got = Eio.Flow.single_read conn buf in
      Eio.traceln "%s" (Cstruct.to_string ~len:got buf);

      Eio.Flow.copy_string "GET / HTTP/1.1\r\nHost:localhost:8081\r\n\r\n" conn;
      let got = Eio.Flow.single_read conn buf in
      Eio.traceln "%s" (Cstruct.to_string ~len:got buf);

      Server.shutdown server
    );;
+HTTP/1.1 400 Bad Request
+Date: Thu, 17 Jun 2021 14:39:38 GMT
+Content-Length: 0
+
+
+HTTP/1.1 400 Bad Request
+Date: Thu, 17 Jun 2021 14:39:38 GMT
+Content-Length: 0
+
+
+HTTP/1.1 200 OK
+Content-Length: 4
+Content-Type: text/plain; charset=uf-8
+Date: Thu, 17 Jun 2021 14:39:38 GMT
+
+root
+HTTP/1.1 200 OK
+Content-Length: 4
+Content-Type: text/plain; charset=uf-8
+Date: Thu, 17 Jun 2021 14:39:38 GMT
+
+root
+HTTP/1.1 200 OK
+Content-Length: 4
+Content-Type: text/plain; charset=uf-8
+Date: Thu, 17 Jun 2021 14:39:38 GMT
+
+root
- : unit = ()
```

## Server.session_pipeline

```ocaml
let make_session_cookie session key = 
  let nonce = Cstruct.of_string "aaaaaaaaaaaa" in
  let session_data = Session.Data.(add "a" "a_val" empty |> add "b" "b_val") in 
  let data = Session.encode ~nonce session_data session in
  Cookie.(add ~name:(Session.cookie_name session) ~value:data empty)
```

```ocaml
# let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA");;
val key : string = "’qQû&ÏW\015Ã&ƒ§ùî¯¤ÓTØŠvgwãÖÅÌ€L–b\016"

# let session = Session.cookie_session key;;
val session : Session.t = <obj>

# let session_cookie = make_session_cookie session key ;;
val session_cookie : Cookie.t = <abstr>

# let headers = Header.(add empty cookie session_cookie);;
val headers : Header.t = <abstr>

# let req = Request.server_request ~headers ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server_request = <obj>

# let handler _ctx = Response.text "hello";;
val handler : 'a -> Response.server_response = <fun>

# let ctx = Context.make req;;
val ctx : Context.t = <abstr>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.session_pipeline session @@ handler) ctx ;;
val res : Response.server_response = <obj>

# let set_cookie = Header.(find_header set_cookie res);; 
val set_cookie : Set_cookie.t = <abstr>

# Set_cookie.name set_cookie;;
- : string = "___SPRING_SESSION___"
```

Response should have Session Set-Cookie if set during request processing.

```ocaml
# let req = Request.server_request ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server_request = <obj>

# let handler ctx =
  let session_data = Session.Data.(add "a" "a_val" empty |> add "b" "b_val") in
  Context.replace_session_data session_data ctx;
  Response.text "hello";;
val handler : Context.t -> Response.server_response = <fun>

# let ctx = Context.make req;;
val ctx : Context.t = <abstr>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.session_pipeline session @@ handler) ctx ;;
val res : Response.server_response = <obj>

# let set_cookie = Header.(find_header set_cookie res);; 
val set_cookie : Set_cookie.t = <abstr>

# Set_cookie.name set_cookie;;
- : string = "___SPRING_SESSION___"

# let session_data' = 
  let data = Set_cookie.value set_cookie in
  Session.decode data session;;
val session_data' : Session.session_data = <abstr>

# Session.Data.find "a" session_data' ;;
- : string = "a_val"

# Session.Data.find "b" session_data' ;;
- : string = "b_val"
```

## Server.anticsrf_pipeline

```ocaml
let write_header b : < f : 'a. 'a Header.header -> 'a -> unit > =
  object
    method f : 'a. 'a Header.header -> 'a -> unit =
      fun hdr v ->
        let v = Header.encode hdr v in
        let name = (Header.name hdr :> string) in
        Header.write_header (Buffer.add_string b) name v
  end

let make_server_request ?(resource="/") ?(headers=Header.empty) (w: #Body.writable) =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    w#write_body bw;
  );
  Eio.traceln "%s" (Buffer.contents b);
  let buf_read = Eio.Buf_read.of_string (Buffer.contents b) in
  let len = String.length @@ Buffer.contents b in
  let headers = Header.(add headers content_length len) in
  Request.server_request ~headers ~resource Method.post client_addr buf_read 

let print_response w =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw -> Response.write w bw);
  Eio.traceln "%s" (Buffer.contents b);;

let anticsrf_token = "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA"
let anticsrf_form_field = "__anticsrf_token__"
let anticsrf_cookie_name = "XCSRF_TOKEN"
let anticsrf_cookie = Cookie.(add ~name:anticsrf_cookie_name ~value:anticsrf_token empty)
let headers = Header.(add empty cookie anticsrf_cookie)
let headers =
  let ct = Content_type.make ("application", "x-www-form-urlencoded") in
  Header.(add headers content_type ct)
```

The pipeline validates anticsrf-token successfully.

```ocaml
# let handler _ctx = Response.text "hello";;
val handler : 'a -> Response.server_response = <fun>

# let form_body = Body.form_values_writer 
  [(anticsrf_form_field, [anticsrf_token]); ("name2", ["val c"; "val d"; "val e"])] ;;
val form_body : Body.writable = <obj>

# let req1 = make_server_request ~headers form_body;;
+__anticsrf_token__=knFR%2BybPVw/DJoOn%2Be6vpNNU2Ip2Z3fj1sXMgEyWYhA&name2=val%20c,val%20d,val%20e
val req1 : Request.server_request = <obj>

# Eio.traceln "%a" Request.pp req1;;
+{
+  Version:  HTTP/1.1;
+  Method:  post;
+  URI:  /;
+  Headers :
+    {
+      Content-Length:  96;
+      Content-Type:  application/x-www-form-urlencoded;
+      Cookie:  XCSRF_TOKEN=knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA
+    };
+  Client Address:  tcp:127.0.0.1:8081
+}
- : unit = ()

# let ctx = Context.make req1;;
val ctx : Context.t = <abstr>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.anticsrf_pipeline ~protected_http_methods:[Method.post] ~anticsrf_form_field ~anticsrf_cookie_name @@ handler) ctx ;;
val res : Response.server_response = <obj>

# print_response res;;
+HTTP/1.1 200 OK
+Content-Length: 5
+Content-Type: text/plain; charset=uf-8
+
+hello
- : unit = ()
```

The pipeline generates `Bad Request` response due to anticsrf_token validation failure.

```ocaml
# let form_body = Body.form_values_writer 
  [(anticsrf_form_field, ["toasdasdfasd"]); ("name2", ["val c"; "val d"; "val e"])] ;;
val form_body : Body.writable = <obj>

# let req1 = make_server_request ~headers form_body;;
+__anticsrf_token__=toasdasdfasd&name2=val%20c,val%20d,val%20e
val req1 : Request.server_request = <obj>

# Eio.traceln "%a" Request.pp req1;;
+{
+  Version:  HTTP/1.1;
+  Method:  post;
+  URI:  /;
+  Headers :
+    {
+      Content-Length:  61;
+      Content-Type:  application/x-www-form-urlencoded;
+      Cookie:  XCSRF_TOKEN=knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA
+    };
+  Client Address:  tcp:127.0.0.1:8081
+}
- : unit = ()

# let ctx = Context.make req1;;
val ctx : Context.t = <abstr>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.anticsrf_pipeline ~protected_http_methods:[Method.post] ~anticsrf_form_field ~anticsrf_cookie_name @@ handler) ctx ;;
val res : Response.server_response = <obj>

# print_response res;;
+HTTP/1.1 400 Bad Request
+Content-Length: 0
+
+
- : unit = ()
```

The pipeline generates Anticsrf Cookie if `Context.anticsrf_token = Some tok`

```ocaml
# let handler ctx = 
  Context.init_anticsrf_token ctx;
  Response.text "hello";; 
val handler : Context.t -> Response.server_response = <fun>

# let req = Request.server_request ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server_request = <obj>

# let ctx = Context.make req;;
val ctx : Context.t = <abstr>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.anticsrf_pipeline ~protected_http_methods:[Method.post] ~anticsrf_form_field ~anticsrf_cookie_name @@ handler) ctx ;;
val res : Response.server_response = <obj>

# Header.(find_header set_cookie res) |> Set_cookie.name;;
- : string = "XCSRF_TOKEN"
```
