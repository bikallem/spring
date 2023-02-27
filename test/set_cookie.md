# Set_cookie tests

```ocaml
open Spring
```

## Set_cookie.decode

```ocaml
# let t = Set_cookie.decode "lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT; Max-Age=2"
val t : Set_cookie.t = <abstr>
```
## Set_cooki.name

```ocaml
# Set_cookie.name t ;;
- : string = "lang"
```

## Set_cookie.value

```ocaml
# Set_cookie.value t;;
- : string = "en-US"
```

## Set_cookie.expires

```ocaml
# Set_cookie.expires t |> Option.get |> Eio.traceln "%a" Ptime.pp ;;
+2021-06-09 10:18:14 +00:00
- : unit = ()
```

## Set_cookie.max_age

```ocaml
# let t = Set_cookie.decode "lang=en-US; Max-Age=2"
val t : Set_cookie.t = <abstr>

# Set_cookie.max_age t;;
- : int option = Some 2

# let t = Set_cookie.decode "lang=en-US; Max-Age=-1"
val t : Set_cookie.t = <abstr>

# Set_cookie.max_age t;;
- : int option = Some (-1)

# let t = Set_cookie.decode "lang=en-US; Max-Age=adasdf"
Exception: Failure "max-age: invalid max-age value".
```

## Set_cookie.domain

```ocaml
# let t = Set_cookie.decode "d=d; Domain=www.example.com";;
val t : Set_cookie.t = <abstr>

# Set_cookie.domain t |> Option.get |> Eio.traceln "%a" Domain_name.pp ;;
+www.example.com
- : unit = ()

# let t = Set_cookie.decode "d=d; Domain=example.org";;
val t : Set_cookie.t = <abstr>

# Set_cookie.domain t |> Option.get |> Eio.traceln "%a" Domain_name.pp ;;
+example.org
- : unit = ()
```

Host only. 

```ocaml
# let t = Set_cookie.decode "d=d; Domain=example-host";;
val t : Set_cookie.t = <abstr>

# Set_cookie.domain t |> Option.get |> Eio.traceln "%a" Domain_name.pp ;;
+example-host
- : unit = ()
```

## Set_cookie.path 

```ocaml
# let t = Set_cookie.decode "d=d; Path=asd\x19fasdf";;
Exception: Failure "path: invalid path value".

# let t = Set_cookie.decode "d=d; Path=path1";;
val t : Set_cookie.t = <abstr>

# Set_cookie.path t;;
- : string option = Some "path1"
```

## Set_cookie.secure

```ocaml
# let t = Set_cookie.decode "d=d; Max-Age=1; Secure";;
val t : Set_cookie.t = <abstr>

# Set_cookie.secure t;;
- : bool = true

# let t = Set_cookie.decode "d=d; Max-Age=1";;
val t : Set_cookie.t = <abstr>

# Set_cookie.secure t;;
- : bool = false
```

## Set_cookie.http_only

```ocaml
# let t = Set_cookie.decode "d=d; Max-Age=1; HttpOnly";;
val t : Set_cookie.t = <abstr>

# Set_cookie.http_only t;;
- : bool = true

# let t = Set_cookie.decode "d=d; Max-Age=1";;
val t : Set_cookie.t = <abstr>

# Set_cookie.http_only t;;
- : bool = false
```

## Set_cookie.extensions

```ocaml
# let t = Set_cookie.decode "d=d; Max-Age=1; HttpOnly; extension1; extension2";;
val t : Set_cookie.t = <abstr>

# Set_cookie.extensions t;;
- : string list = ["extension2"; "extension1"]
```

## Set_cookie.make 

```ocaml
# let t = Set_cookie.make ~max_age:2 ("d","d");;
val t : Set_cookie.t = <abstr>

# Set_cookie.name t;;
- : string = "d"

# Set_cookie.value t;;
- : string = "d"

# Set_cookie.max_age t;;
- : int option = Some 2
```

## Set_cookie.pp

```ocaml
# let t = Set_cookie.decode "SID=31d4d96e407aad42; Path=/; Domain=example.com; Secure; HttpOnly; \
     Expires=Sun, 06 Nov 1994 08:49:37 GMT; extension1; extension2; extension3" ;;
val t : Set_cookie.t = <abstr>

# Eio.traceln "%a" Set_cookie.pp t;;
+{
+  Name:  SID;
+  Value:  31d4d96e407aad42;
+  Expires:  Sun, 06 Nov 1994 08:49:37 GMT;
+  Domain:  example.com;
+  Path:  /;
+  Secure;
+  HttpOnly;
+  extension1;
+  extension2;
+  extension3
+}
- : unit = ()
```

## Set_cookie.expire

```ocaml
# let t = Set_cookie.decode "SID=31d4d96e407aad42; Path=/; Domain=example.com; Secure; HttpOnly; \
     Expires=Sun, 06 Nov 1994 08:49:37 GMT; extension1; extension2; extension3" ;;
val t : Set_cookie.t = <abstr>

# Set_cookie.expire t |> Eio.traceln "%a" Set_cookie.pp;;
+{
+  Name:  SID;
+  Value;
+  Max-Age:  -1
+}
- : unit = ()
```
