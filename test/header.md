## Header tests

```ocaml
open Spring
```

## Name/Canonical names 

`canonical_name`

```ocaml
# Header.canonical_name "accept-encoding";;
- : Header.name = "Accept-Encoding"

# Header.canonical_name "content-length";;
- : Header.name = "Content-Length"

# Header.canonical_name "Age";;
- : Header.name = "Age"

# Header.canonical_name "cONTENt-tYPE";;
- : Header.name = "Content-Type"
```

`lname`

```ocaml
# let content_type = Header.lname "Content-type";;
val content_type : Header.lname = "content-type"

# let age = Header.lname "Age";;
val age : Header.lname = "age"
```

## Creation

```ocaml
# let l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")];;
val l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")]

# let headers = Header.of_list l ;;
val headers : Header.t = <abstr>

# Header.to_list headers;;   
- : (Header.lname * string) list =
[("content-type", "text/html"); ("age", "40");
 ("transfer-encoding", "chunked"); ("content-length", "2000")]

# Header.to_canonical_list headers ;;
- : (Header.name * string) list =
[("Content-Type", "text/html"); ("Age", "40");
 ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")]
```

## Add

```ocaml
# let h = Header.(add empty content_length 10);;
val h : Header.t = <abstr>

# let h = Header.(add h content_length 20);;
val h : Header.t = <abstr>

# let ct = Content_type.make ("text", "plain");;
val ct : Content_type.t = <abstr>

# let h = Header.(add h content_type ct);;
val h : Header.t = <abstr>

# let h = Header.(add_unless_exists h content_length 20);;
val h : Header.t = <abstr>
```

## Find

```ocaml
# Header.(find h content_length);;
- : int option = Some 20

# Header.(find h content_length);;
- : int option = Some 20

# Header.(find_all h content_length);;
- : int list = [20; 10]

# Header.(exists h content_length);;
- : bool = true

# Header.(exists h content_type);;
- : bool = true
```

## Update/Remove

```ocaml
# let h1 = Header.(remove headers content_length) ;;
val h1 : Header.t = <abstr>

# Header.(find h1 content_length);;
- : int option = None

# Header.to_list h;;
- : (Header.lname * string) list =
[("content-type", "text/plain"); ("content-length", "20");
 ("content-length", "10")]

# let h2 = Header.(replace h content_length 300);;
val h2 : Header.t = <abstr>

# Header.to_list h2;;
- : (Header.lname * string) list =
[("content-type", "text/plain"); ("content-length", "300")]

# Header.(find h2 content_length);;
- : int option = Some 300

# Header.(find_all h2 content_length);;
- : int list = [300]
```

## Header.parse


```ocaml
# let hdr = "Host: localhost:1234\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\nAccept-Language: en-GB,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nContent-Type: multipart/form-data; boundary=---------------------------39502568731012728120453570260\r\nContent-Length: 10063\r\nDNT: 1\r\nConnection: keep-alive\r\nUpgrade-Insecure-Requests: 1\r\n\r\n" ;;
val hdr : string =
  "Host: localhost:1234\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\nAccept-Language: en-GB,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nContent-Type: multipart/form-data; boundary=--"... (* string length 442; truncated *)

# let t = Header.parse @@ Eio.Buf_read.of_string hdr ;;
val t : Header.t = <abstr>

# Header.(find t host);;
- : string option = Some "localhost:1234"

# Header.(find t content_length);;
- : int option = Some 10063
```

## Header.content_type/content_disposition

```ocaml
# let hdr = "Content-Disposition: form-data; name=\"name\"; filename=\"New document 1.2020_08_01_13_16_42.0.svg\"\r\nContent-Type: image/svg+xml\r\n\r\n" ;;
val hdr : string =
  "Content-Disposition: form-data; name=\"name\"; filename=\"New document 1.2020_08_01_13_16_42.0.svg\"\r\nContent-Type: image/svg+xml\r\n\r\n"

# let t = Header.parse @@ Eio.Buf_read.of_string hdr ;;
val t : Header.t = <abstr>

# Header.(find t content_type) |> Option.iter (fun x -> Eio.traceln "%s" (Content_type.encode x)) ;;
+image/svg+xml
- : unit = ()

# Header.(find t content_disposition) |> Option.iter (fun x -> Eio.traceln "%s" (Content_disposition.encode x)) ;;
+form-data; filename="New document 1.2020_08_01_13_16_42.0.svg"; name="name"
- : unit = ()
```

## Header.cookie

```ocaml
# let t = Header.parse (Eio.Buf_read.of_string "Cookie: SID=31d4d96e407aad42; lang=en\r\n\r\n");;
val t : Header.t = <abstr>

# let cookies = Header.(find t cookie) |> Option.get ;;
val cookies : Cookie.t = <abstr>

# Cookie.find cookies "SID";;
- : string option = Some "31d4d96e407aad42"

# Cookie.find cookies "lang";;
- : string option = Some "en"
```

## Header.write

```ocaml
# let l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")];;
val l : (string * string) list =
  [("Content-Type", "text/html"); ("Age", "40");
   ("Transfer-Encoding", "chunked"); ("Content-Length", "2000")]

# let headers = Header.of_list l ;;
val headers : Header.t = <abstr>

# let b = Buffer.create 10;;
val b : Buffer.t = <abstr>

# Header.write headers (Buffer.add_string b) ;;
- : unit = ()

# Buffer.contents b;;
- : string =
"Content-Type: text/html\r\nAge: 40\r\nTransfer-Encoding: chunked\r\nContent-Length: 2000\r\n"
```
