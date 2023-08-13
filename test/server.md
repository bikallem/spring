# Server

```ocaml
open Spring 

let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)

let now = ref 1623940778.27033591

let fake_clock real_clock = object (_ : #Eio.Time.clock)
  method now = !now
  method sleep_until time =
    now := max !now time
end

type request = Request.server Request.t

let handler req =
  match Request.resource req with
  | "/" -> Response.text "root"
  | "/upload" -> (
    match Request.readable req |> Body.read_content with
    | Some a -> Response.text a
    | None -> Response.bad_request)
  | _ -> Response.not_found
```

### Server.run/Server.run_local

<!-- $MDX set-SPRING_MASTER_KEY=knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA -->
```ocaml
# Eio_main.run @@ fun env ->
  let server = Server.make ~on_error:raise ~secure_random:env#secure_random 
    ~make_handler:(fun _ -> handler) env#clock env#net 
  in
  Eio.Fiber.both 
    (fun () -> Server.run_local ~port:8081 server)
    (fun () ->
      Eio.Switch.run @@ fun sw ->
      let client = Client.make sw env#net in
      let body = 
        Client.get client "localhost:8081" (fun res ->
          Eio.traceln "Route: /";
          Eio.traceln "%a" Headers.pp (Response.headers res);
          let body = Response.readable res in
          Eio.traceln "%s" (Body.read_content body |> Option.get);
          Eio.traceln "";
          Eio.traceln "Route: /upload";
          let body =
            let content_type = Content_type.make ("text", "plain") in
            Body.writable_content content_type "hello world" 
          in
          body)
      in
      Client.post client body "localhost:8081/upload" (fun res ->
        Eio.traceln "%a" Headers.pp (Response.headers res);
        let body = Response.readable res in
        Eio.traceln "%s" (Body.read_content body |> Option.get));
      Server.shutdown server
    );;
+Route: /
+[
+  Content-Length: 4;
+  Content-Type: text/plain; charset=uf-8
+]
+root
+
+Route: /upload
+[
+  Content-Length: 11;
+  Content-Type: text/plain; charset=uf-8
+]
+hello world
- : unit = ()
```

### Server.pipeline  

A `router` pipeline is a simple `Request.resource` based request router. It only handles resource path "/" and delegates the rest to the builtin `Server.not_found_handler`. When a request is sent with "/" then we get a "hello, there" text response. However, if we try with any other resource path, we get `404 Not Found` response.

```ocaml
let router : Server.pipeline =
  fun next req ->
    match Request.resource req with
    | "/" -> Response.text "hello, there"
    | _ -> next req

let final_handler : Server.handler = router @@ Server.not_found_handler
```

```ocaml
# Eio_main.run @@ fun env ->
  let server = 
    Server.make ~on_error:raise ~secure_random:env#secure_random 
        ~make_handler:(fun _ -> final_handler) env#clock env#net 
  in
  Eio.Fiber.both 
    (fun () -> Server.run_local ~port:8081 server)
    (fun () ->
      Eio.Switch.run @@ fun sw ->
      let client = Client.make sw env#net in
      Client.get client "localhost:8081" (fun res ->
          let body = Response.readable res in
          Eio.traceln "Resource (/): %s" (Body.read_content body |> Option.get)); 

      Client.get client "localhost:8081/products" (fun res ->
          Eio.traceln "Resource (/products) : %a" Status.pp (Response.status res));

      Server.shutdown server
    );;
+Resource (/): hello, there
+Resource (/products) : 404 Not Found
- : unit = ()
```

### Server.host_header

```ocaml
let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)

let make_buf_read version meth connection = 
  let s = Printf.sprintf "%s /products HTTP/%s\r\nConnection: %s\r\nTE: trailers\r\nUser-Agent: cohttp-eio\r\n\r\n" meth version connection in
  Eio.Buf_read.of_string s

let hello _req = Response.text "hello"
```

Try with GET method.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.1" "get" "";;
val r : Request.server Request.t = <abstr>

# let res1 = (Server.host_header @@ hello) r;;
val res1 : Server.response = <abstr>

# Eio.traceln "%a" Response.pp res1 ;;
+{
+  Version: HTTP/1.1;
+  Status: 400 Bad Request;
+  Headers: [
+             Content-Length: 0
+           ]
+}
- : unit = ()
```

Try with POST method.

```ocaml
# let r = Request.parse_server_request client_addr @@ make_buf_read "1.1" "post" "";;
val r : Request.server Request.t = <abstr>

# let res1 = (Server.host_header @@ hello) r;;
val res1 : Server.response = <abstr>

# Eio.traceln "%a" Response.pp res1 ;;
+{
+  Version: HTTP/1.1;
+  Status: 400 Bad Request;
+  Headers: [
+             Content-Length: 0
+           ]
+}
- : unit = ()
```

A valid request with HOST header is processed okay.

```ocaml
# let buf_read = Printf.sprintf "%s /products HTTP/%s\r\nHost: www.example.com\r\nConnection: %s\r\nTE: trailers\r\nUser-Agent: cohttp-eio\r\n\r\n" "get" "1.1" ""
  |> Eio.Buf_read.of_string ;;
val buf_read : Eio.Buf_read.t = <abstr>

# let r = Request.parse_server_request client_addr buf_read;;
val r : Request.server Request.t = <abstr>

# let res1 = (Server.host_header @@ hello) r;;
val res1 : Server.response = <abstr>

# Eio.traceln "%a" Response.pp res1 ;;
+{
+  Version: HTTP/1.1;
+  Status: 200 OK;
+  Headers: [
+
+           ]
+}
- : unit = ()
```

### Server.response_date

```ocaml
let mock_clock = Eio_mock.Clock.make ()
let () = Eio_mock.Clock.set_time mock_clock 1666627935.85052109
```

A Date header is added to a 200 response.

```ocaml
# let hello _req = Response.text "hello, world!" ;;
val hello : 'a -> Response.server Response.t = <fun>

# let req = Request.make_server_request ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server Request.t = <abstr>

# let h = Server.(response_date mock_clock) @@ hello ;;
val h : Server.handler = <fun>

# Eio.traceln "%a" Response.pp @@ h req;;
+{
+  Version: HTTP/1.1;
+  Status: 200 OK;
+  Headers: [
+             Date: Mon, 24 Oct 2022 16:12:15 GMT
+           ]
+}
- : unit = ()
```

A Date header is not added added to a 5xx status response. We use server_request `req` from above.

```ocaml
# let h _req = Response.make_server_response ~status:Status.internal_server_error Body.none ;;
val h : 'a -> Response.server Response.t = <fun>

# let h= Server.response_date mock_clock @@ h ;;
val h : Server.handler = <fun>

# Eio.traceln "%a" Response.pp @@ h req;;
+{
+  Version: HTTP/1.1;
+  Status: 500 Internal Server Error;
+  Headers: [
+
+           ]
+}
- : unit = ()
```

A Date header is not added added to a 1xx status response. We use server_request `req` from above.

```ocaml
# let h _req = Response.make_server_response ~status:Status.continue Body.none ;;
val h : 'a -> Response.server Response.t = <fun>

# let h= Server.response_date mock_clock @@ h ;;
val h : Server.handler = <fun>

# Eio.traceln "%a" Response.pp @@ h req;;
+{
+  Version: HTTP/1.1;
+  Status: 100 Continue;
+  Headers: [
+
+           ]
+}
- : unit = ()
```


### Server.host_header/response_data

Check that "Host" header value is validated. See https://www.rfc-editor.org/rfc/rfc9112#section-3.2

```ocaml
# Eio_main.run @@ fun env ->
  let make_handler _t = 
    Server.response_date (fake_clock env#clock) 
    @@ Server.host_header
    @@ handler 
  in
  let server = 
    Server.make ~on_error:raise ~secure_random:env#secure_random ~make_handler 
        env#clock env#net 
  in 
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

### Server.session_pipeline

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

# let session = Session.cookie_codec key;;
val session : Session.codec = <abstr>

# let session_cookie = make_session_cookie session key ;;
val session_cookie : Cookie.t = <abstr>

# let headers = Headers.(add cookie session_cookie empty);;
val headers : Headers.t = <abstr>

# let req = Request.make_server_request ~headers ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server Request.t = <abstr>

# let handler _req = Response.text "hello";;
val handler : 'a -> Response.server Response.t = <fun>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.session_pipeline session @@ handler) req ;;
val res : Server.response = <abstr>

# let set_cookie = Headers.(find set_cookie @@ Response.headers res);; 
val set_cookie : Set_cookie.t = <abstr>

# Set_cookie.name set_cookie;;
- : string = "___SPRING_SESSION___"
```

Response should have Session Set-Cookie if set during request processing.

```ocaml
# let req = Request.make_server_request ~resource:"/products" Method.get client_addr (Eio.Buf_read.of_string "") ;;
val req : Request.server Request.t = <abstr>

# let handler req =
  let session_data = Session.Data.(add "a" "a_val" empty |> add "b" "b_val") in
  Request.replace_session_data session_data req;
  Response.text "hello";;
val handler : Request.server Request.t -> Response.server Response.t = <fun>

# let res = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  (Server.session_pipeline session @@ handler) req ;;
val res : Server.response = <abstr>

# let set_cookie = Headers.(find set_cookie @@ Response.headers res);; 
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

### Tls Server and Client

```ocaml
let server_certificates env =
  let ( / ) = Eio.Path.( / ) in
  let dir = env#cwd in
  let priv_key = dir / "server.key" in
  let cert = dir / "server.pem" in
  (priv_key, cert)
                
let say_hello _req = Response.text "Hello, world!"                
```

```ocaml
# Eio_main.run @@ fun env ->
  let tls_certificates = server_certificates env in
  let server =
    Server.make ~on_error:raise ~secure_random:env#secure_random
      ~make_handler:(fun _ -> say_hello)
      env#clock env#net
  in
  Eio.Fiber.both
    (fun () ->
      Eio.traceln "server -> start";
      Server.run_local ~tls_certificates ~port:8080 server;
      Eio.traceln "server done.")
    (fun () ->
      Eio.traceln "client -> start";
      Eio.Switch.run @@ fun sw ->
      let client = Client.make ~authenticate_tls:false sw env#net in
      Client.get client "https://localhost:8080/hello" (fun res ->
          let body = Response.readable res in
          Eio.traceln "client <- %s" (Body.read_content body |> Option.get));
      Eio.traceln "client done.";
      Server.shutdown server)
    ;;
+server -> start
+client -> start
+client <- Hello, world!
+client done.
+server done.
- : unit = ()
```
