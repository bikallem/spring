## Header tests

```ocaml
open Spring
```

## Name/Canonical names 

`Definition.canonical_name`

```ocaml
# Headers.Definition.canonical_name "accept-encoding";;
- : Headers.Definition.name = "Accept-Encoding"

# Headers.Definition.canonical_name "content-length";;
- : Headers.Definition.name = "Content-Length"

# Headers.Definition.canonical_name "Age";;
- : Headers.Definition.name = "Age"

# Headers.Definition.canonical_name "cONTENt-tYPE";;
- : Headers.Definition.name = "Content-Type"
```

`Definition.lname`

```ocaml
# let content_type = Headers.Definition.lname "Content-type";;
val content_type : Headers.Definition.lname = "content-type"

# let age = Headers.Definition.lname "Age";;
val age : Headers.Definition.lname = "age"
```

## Creation

```ocaml
# let l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")];;
val l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")]

# let headers = Headers.of_list l ;;
val headers : Headers.t = <abstr>

# Headers.to_list headers;;   
- : (Headers.Definition.lname * string) list =
[("content-type", "text/html"); ("age", "40");
 ("transfer-encoding", "chunked"); ("content-length", "2000")]
```

## Add

```ocaml
# let h = Headers.(add content_length 10 empty);;
val h : Headers.t = <abstr>

# let h = Headers.(add content_length 20 h);;
val h : Headers.t = <abstr>

# let ct = Content_type.make ("text", "plain");;
val ct : Content_type.t = <abstr>

# let h = Headers.(add content_type ct h);;
val h : Headers.t = <abstr>

# let h = Headers.(add_unless_exists content_length 20 h);;
val h : Headers.t = <abstr>
```

## Find

```ocaml
# Headers.(find_opt content_length h);;
- : int option = Some 20

# Headers.(find_opt content_length h);;
- : int option = Some 20

# Headers.(find_all content_length h);;
- : int list = [20; 10]

# Headers.(exists content_length h);;
- : bool = true

# Headers.(exists content_type h);;
- : bool = true
```

## Headers.replace 

```ocaml
# let h1 = Headers.(remove content_length headers) ;;
val h1 : Headers.t = <abstr>

# Headers.(find_opt content_length h1);;
- : int option = None

# Headers.to_list h;;
- : (Headers.Definition.lname * string) list =
[("content-type", "text/plain"); ("content-length", "20");
 ("content-length", "10")]

# let h2 = Headers.(replace content_length 300 h);;
val h2 : Headers.t = <abstr>

# Headers.to_list h2;;
- : (Headers.Definition.lname * string) list =
[("content-type", "text/plain"); ("content-length", "300")]

# Headers.(find_opt content_length h2);;
- : int option = Some 300

# Headers.(find_all content_length h2);;
- : int list = [300]
```

Add the header if it doesn't exist yet.

```ocaml
# let h = Headers.(replace host "www.example.com" empty) in
  Headers.(find_opt host h);;
- : string option = Some "www.example.com"
```

## Headers.remove_all

```ocaml
# let h1 = Headers.of_list ["user-agent", "234"; "user-agent", "123"];;
val h1 : Headers.t = <abstr>

# Headers.(find_all user_agent h1);;
- : string list = ["234"; "123"]

# let h1 = Headers.(remove user_agent h1);;
val h1 : Headers.t = <abstr>

# Headers.(find_all user_agent h1);;
- : string list = []
```

# Headers.remove_first

```ocaml
# let h1 = Headers.of_list ["user-agent", "234"; "user-agent", "123"];;
val h1 : Headers.t = <abstr>

# Headers.(find_all user_agent h1);;
- : string list = ["234"; "123"]

# let h1 = Headers.(remove_first user_agent h1);;
val h1 : Headers.t = <abstr>

# Headers.(find_all user_agent h1);;
- : string list = ["123"]
```

## Headers.parse

```ocaml
# let hdr = "Host: localhost:1234\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\nAccept-Language: en-GB,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nContent-Type: multipart/form-data; boundary=---------------------------39502568731012728120453570260\r\nContent-Length: 10063\r\nDNT: 1\r\nConnection: keep-alive\r\nUpgrade-Insecure-Requests: 1\r\n\r\n" ;;
val hdr : string =
  "Host: localhost:1234\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\nAccept-Language: en-GB,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nContent-Type: multipart/form-data; boundary=--"... (* string length 442; truncated *)

# let t = Headers.parse @@ Eio.Buf_read.of_string hdr ;;
val t : Headers.t = <abstr>

# Headers.(find_opt host t);;
- : string option = Some "localhost:1234"

# Headers.(find_opt content_length t);;
- : int option = Some 10063
```

## Headers.content_type/content_disposition

```ocaml
# let hdr = "Content-Disposition: form-data; name=\"name\"; filename=\"New document 1.2020_08_01_13_16_42.0.svg\"\r\nContent-Type: image/svg+xml\r\n\r\n" ;;
val hdr : string =
  "Content-Disposition: form-data; name=\"name\"; filename=\"New document 1.2020_08_01_13_16_42.0.svg\"\r\nContent-Type: image/svg+xml\r\n\r\n"

# let t = Headers.parse @@ Eio.Buf_read.of_string hdr ;;
val t : Headers.t = <abstr>

# Headers.(find_opt content_type t) |> Option.iter (fun x -> Eio.traceln "%s" (Content_type.encode x)) ;;
+image/svg+xml
- : unit = ()

# Headers.(find_opt content_disposition t) |> Option.iter (fun x -> Eio.traceln "%s" (Content_disposition.encode x)) ;;
+form-data; filename="New document 1.2020_08_01_13_16_42.0.svg"; name="name"
- : unit = ()
```

## Headers.cookie

```ocaml
# let t = Headers.parse (Eio.Buf_read.of_string "Cookie: SID=31d4d96e407aad42; lang=en\r\n\r\n");;
val t : Headers.t = <abstr>

# let cookies = Headers.(find_opt cookie t) |> Option.get ;;
val cookies : Cookie.t = <abstr>

# Cookie.find_opt "SID" cookies;;
- : string option = Some "31d4d96e407aad42"

# Cookie.find_opt "lang" cookies;;
- : string option = Some "en"
```

## Headers.write

```ocaml
let test_writer f =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s f;
  Eio.traceln "%s" (Buffer.contents b);;
```

```ocaml
# let l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")];;
val l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")]

# let headers = Headers.of_list l ;;
val headers : Headers.t = <abstr>

# test_writer @@ fun bw -> Headers.write bw headers;;
+Content-Type: text/html
+Age: 40
+Transfer-Encoding: chunked
+Content-Length: 2000
+
- : unit = ()
```

## Headers.header values

```ocaml
let test_header d pp t =
  Eio.traceln "Find: %a" pp @@ Headers.(find d t);
  Eio.traceln "Headers.pp: %a" Headers.pp t;;
```

Last-Modified header.

```ocaml
# test_header Headers.last_modified Date.pp
    @@ Headers.of_list ["last-modified","Wed, 28 Jun 2023 10:55:19 GMT"];;
+Find: Wed, 28 Jun 2023 10:55:19 GMT
+Headers.pp: [
+              Last-Modified: Wed, 28 Jun 2023 10:55:19 GMT
+            ]
- : unit = ()
```

If-Modified-Since header.

```ocaml
# test_header Headers.if_modified_since Date.pp
    @@ Headers.of_list ["if-modified-since", "Wed, 28 Jun 2023 10:55:19 GMT"];;
+Find: Wed, 28 Jun 2023 10:55:19 GMT
+Headers.pp: [
+              If-Modified-Since: Wed, 28 Jun 2023 10:55:19 GMT
+            ]
- : unit = ()
```

Expires header.

```ocaml
# test_header Headers.expires Expires.pp 
    @@ Headers.of_list ["expires", "Wed, 28 Jun 2023 10:55:19 GMT"];;
+Find: Wed, 28 Jun 2023 10:55:19 GMT
+Headers.pp: [
+              Expires: Wed, 28 Jun 2023 10:55:19 GMT
+            ]
- : unit = ()
```

ETag header.

```ocaml
# test_header Headers.etag Etag.pp 
    @@ Headers.of_list ["etag", {|"r2d2xxxx"|}];;
+Find: "r2d2xxxx"
+Headers.pp: [
+              Etag: "r2d2xxxx"
+            ]
- : unit = ()
```

If-None-Match header.

```ocaml
# test_header Headers.if_none_match If_none_match.pp 
    @@ Headers.of_list ["if-none-match", {|"xyzzy", W/"r2d2xxxx", "c3piozzz", W/"c3piozzzz"|}];;
+Find: "xyzzy", W/"r2d2xxxx", "c3piozzz", W/"c3piozzzz"
+Headers.pp: [
+              If-None-Match: "xyzzy", W/"r2d2xxxx", "c3piozzz", W/"c3piozzzz"
+            ]
- : unit = ()
```

Cache-Control header.

```ocaml
# test_header Headers.cache_control Cache_control.pp 
    @@ Headers.of_list ["cache-control", {|max-age=604800, must-revalidate, no-store, private, public, custom1="val1"|}];;
+Find: max-age=604800, must-revalidate, no-store, private, public, custom1="val1"
+Headers.pp: [
+              Cache-Control:
+                max-age=604800, must-revalidate, no-store, private, public, custom1="val1"
+            ]
- : unit = ()
```
