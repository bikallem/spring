# Client

## Client.get and Connection caching/reuse

Setup

```ocaml
open Spring

let addr1 = `Tcp (Eio.Net.Ipaddr.V4.loopback, 80)
let addr2 = `Tcp (Eio.Net.Ipaddr.of_raw "\001\002\003\004", 8080)
let net = Eio_mock.Net.make "net"
let () = Eio_mock.Net.on_getaddrinfo net [`Return [addr1;addr2]; `Return [addr1;addr2]]

let example_com_conn = Eio_mock.Flow.make "www.example.com"
let () = Eio_mock.Flow.on_read 
  example_com_conn
  [
   `Yield_then (`Return "HTTP/1.1 200 OK\r\n");
   `Return "content-length: 5\r\n\r\n";
   `Return "hello";
   `Yield_then (`Return "HTTP/1.1 200 OK\r\n");
   `Return "content-length: 5\r\n\r\n";
   `Return "world";
   `Raise End_of_file
  ]

let mirage_org_conn = Eio_mock.Flow.make "www.mirage.org"
let () = Eio_mock.Flow.on_read
  mirage_org_conn 
  [
   `Yield_then (`Return "HTTP/1.1 200 OK\r\n");
   `Return "content-length: 12\r\n\r\n";
   `Return "Hello again!";
   `Raise End_of_file
  ]

let () = Eio_mock.Net.on_connect net [ `Return example_com_conn; `Return mirage_org_conn]

let test_client f =
  Eio_mock.Backend.run @@ fun () ->
  Eio.Switch.run @@ fun sw ->
  let t = Client.make sw net in
  f t
```

The first call `Client.get "www.example.com"` establishes a connection to host "www.example.com".
The second `Client.get t "www.example.com/products"` doesn't establish the connection since the connection 
to host "www.example.com" is already established and is cached in `t`.

The third call "Client.get t "www.mirage.org:8080" establishes a new connection as it is a new host. Additionally,
note that we can specify port in the url.

```ocaml
# Eio_mock.Backend.run @@ fun () ->
  Eio.Switch.run @@ fun sw ->
  let t = Client.make sw net in
  Client.get t "www.example.com" (fun res ->
    let body = Response.readable res in
    Eio.traceln "%s" (Body.read_content body |> Option.get));

  Client.get t "www.example.com/products" (fun res ->
    let body = Response.readable res in
    Eio.traceln "%s" (Body.read_content body |> Option.get));

  Client.get t "www.mirage.org:8080" (fun res ->
    let body = Response.readable res in
    Eio.traceln "%s" (Body.read_content body |> Option.get))
  ;;
+net: getaddrinfo ~service:80 www.example.com
+net: connect to tcp:127.0.0.1:80
+www.example.com: wrote "get / HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 5\r\n"
+                      "\r\n"
+www.example.com: read "hello"
+hello
+www.example.com: wrote "get /products HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 5\r\n"
+                      "\r\n"
+www.example.com: read "world"
+world
+net: getaddrinfo ~service:8080 www.mirage.org
+net: connect to tcp:127.0.0.1:80
+www.mirage.org: wrote "get / HTTP/1.1\r\n"
+                      "Host: www.mirage.org:8080\r\n"
+                      "Connection: TE\r\n"
+                      "Te: trailers\r\n"
+                      "User-Agent: spring\r\n"
+                      "\r\n"
+www.mirage.org: read "HTTP/1.1 200 OK\r\n"
+www.mirage.org: read "content-length: 12\r\n"
+                     "\r\n"
+www.mirage.org: read "Hello again!"
+Hello again!
+www.mirage.org: closed
+www.example.com: closed
- : unit = ()
```

## Client.head


```ocaml
let test_client f = 
  Eio_mock.Net.on_getaddrinfo net [`Return [addr1;addr2]];
  Eio_mock.Net.on_connect net [`Return example_com_conn];
  Eio_mock.Flow.on_read
    example_com_conn
    [
     `Yield_then (`Return "HTTP/1.1 200 OK\r\n");
     `Return "content-length: 0\r\n\r\n";
     `Raise End_of_file
    ];
  Eio_mock.Backend.run @@ fun () ->
  Eio.Switch.run @@ fun sw ->
  let t = Client.make sw net in
  f t @@ fun _ -> ()
```

```ocaml
# test_client @@ fun t -> Client.head t "www.example.com" ;;
+net: getaddrinfo ~service:80 www.example.com
+net: connect to tcp:127.0.0.1:80
+www.example.com: wrote "head / HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 0\r\n"
+                      "\r\n"
+www.example.com: closed
- : unit = ()
```

## Client.post

```ocaml
# test_client @@ fun t ->
  let content_type = Content_type.make ("text", "plain") in
  let body = Body.writable_content content_type "hello world" in
  Client.post t body "www.example.com/upload" ;;
+net: getaddrinfo ~service:80 www.example.com
+net: connect to tcp:127.0.0.1:80
+www.example.com: wrote "post /upload HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Content-Length: 11\r\n"
+                       "Content-Type: text/plain\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+                       "hello world"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 0\r\n"
+                      "\r\n"
+www.example.com: closed
- : unit = ()
```

## Client.post_form_values

```ocaml
# test_client @@ fun t ->
  let form = [("name1", ["val a"; "val b"; "val c"]); ("name2", ["val c"; "val d"; "val e"])] in
  Client.post_form_values t form "www.example.com/upload";;
+net: getaddrinfo ~service:80 www.example.com
+net: connect to tcp:127.0.0.1:80
+www.example.com: wrote "post /upload HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Content-Length: 59\r\n"
+                       "Content-Type: application/x-www-form-urlencoded\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+                       "name1=val%20a,val%20b,val%20c&name2=val%20c,val%20d,val%20e"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 0\r\n"
+                      "\r\n"
+www.example.com: closed
- : unit = ()
```

## Client.do_call

```ocaml
# test_client @@ fun t -> 
  let req = Request.make_client_request ~host:"www.example.com" ~resource:"/" Method.delete Body.none in
  Client.do_call t req ;;
+net: getaddrinfo ~service:80 www.example.com
+net: connect to tcp:127.0.0.1:80
+www.example.com: wrote "delete / HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 0\r\n"
+                      "\r\n"
+www.example.com: closed
- : unit = ()
```

## Client.call

```ocaml
let () = Eio_mock.Net.on_getaddrinfo net [`Return [addr1;addr2]]
let () = Eio_mock.Net.on_connect net [`Return example_com_conn]
let () = Eio_mock.Flow.on_read
    example_com_conn
    [
     `Yield_then (`Return "HTTP/1.1 200 OK\r\n");
     `Return "content-length: 0\r\n\r\n";
     `Raise End_of_file
    ]
```

```ocaml
# Eio_mock.Backend.run @@ fun () ->
  let req = Request.make_client_request ~host:"www.example.com" ~resource:"/" Method.get Body.none in
  Client.call ~conn:example_com_conn req ;;
+www.example.com: wrote "get / HTTP/1.1\r\n"
+                       "Host: www.example.com\r\n"
+                       "Connection: TE\r\n"
+                       "Te: trailers\r\n"
+                       "User-Agent: spring\r\n"
+                       "\r\n"
+www.example.com: read "HTTP/1.1 200 OK\r\n"
+www.example.com: read "content-length: 0\r\n"
+                      "\r\n"
- : Client.response = <abstr>
```

## Timeout

```ocaml
# Eio_main.run @@ fun env ->
  try
    Eio.Switch.run @@ fun sw ->
    let timeout = Eio.Time.Timeout.seconds env#mono_clock 0.01 in
    let t = Client.make ~timeout sw env#net in
    Eio.traceln "Timeout: %a" Eio.Time.Timeout.pp (Client.timeout t);
    Client.get t "www.example.com" @@ fun (_:Response.client Response.t) -> ()
  with 
    | Eio.Time.Timeout -> ()
    | Eio.Io _ -> ();;
+Timeout: 10ms
- : unit = ()
```
