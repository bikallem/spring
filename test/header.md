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

# let h = Header.(add h content_type "text/plain");;
val h : Header.t = <abstr>

# let h = Header.(add_unless_exists h content_length 20);;
val h : Header.t = <abstr>
```

## Find

```ocaml
# Header.(find h content_length);;
- : int = 20

# Header.(find_opt h content_length);;
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
Exception: Not_found.

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
- : int = 300

# Header.(find_all h2 content_length);;
- : int list = [300]
```
