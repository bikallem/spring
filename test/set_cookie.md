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
# Set_cookie.expires t |> Option.get |> Eio.traceln "%a" Date.pp ;;
+Wed, 09 Jun 2021 10:18:14 GMT
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
     Expires=Sun, 06 Nov 1994 08:49:37 GMT; SameSite=Strict; extension1; extension2; extension3" ;;
val t : Set_cookie.t = <abstr>

# Eio.traceln "%a" Set_cookie.pp t;;
+{
+  Name: SID;
+  Value: 31d4d96e407aad42;
+  Expires: Sun, 06 Nov 1994 08:49:37 GMT;
+  Max-Age: ;
+  Domain: example.com;
+  Path: /;
+  SameSite: Strict;
+  Secure: true;
+  HttpOnly: true
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
+  Name: SID;
+  Value: ;
+  Expires: ;
+  Max-Age: -1;
+  Domain: ;
+  Path: ;
+  SameSite: ;
+  Secure: false;
+  HttpOnly: false
+}
- : unit = ()
```

## Set_cookie.same_site

```ocaml
# let t = Set_cookie.decode "SID=31d4d96e407aad42; path=/; domain=example.com; secure; httponly; \
     Expires=Sun, 06 Nov 1994 08:49:37 GMT; samesite=Strict; extension1; extension2; extension3" ;;
val t : Set_cookie.t = <abstr>

# Set_cookie.same_site t;;
- : Set_cookie.same_site option = Some "Strict"

# let t = Set_cookie.decode "SID=31d4d96e407aad42; Path=/; Domain=example.com; Secure; HttpOnly; \
     Expires=Sun, 06 Nov 1994 08:49:37 GMT; SameSite=Lax; extension1; extension2; extension3" ;;
val t : Set_cookie.t = <abstr>

# Set_cookie.same_site t;;
- : Set_cookie.same_site option = Some "Lax"
```

## Set_cookie.encode

```ocaml
# Set_cookie.encode t;;
- : string =
"SID=31d4d96e407aad42; Path=/; Domain=example.com; Expires=Sun, 06 Nov 1994 08:49:37 GMT; SameSite=Lax; Secure; HttpOnly"
```

`New`

# Set-Cookie

1. Make a `Set-Cookie` value `t` with extension parameter.
2. Display name
3. Display value
4. Display extension value.

```ocaml
# let t = Set_cookie.New.make ~extension:"hello" ~name:"cookie1" "val1";;
val t : Set_cookie.New.t = <abstr>

# Set_cookie.New.name t;;
- : string = "cookie1"

# Set_cookie.New.value t;;
- : string = "val1"

# Set_cookie.New.extension t;;
- : string option = Some "hello"
```

## Add and find attributes in Set-Cookie

Expires attribute.

1. Create Date.t value `dt1`.
2. Add `Expires` attribute with `dt1` `t`.
3. Find `Expires` attribute in `t` to `dt2`.
4. `dt1` is equal to `dt2`.

```ocaml
let dt1 = Date.of_float_s 1623940778.27033591 |> Option.get
```

```ocaml
# let t = Set_cookie.New.(add expires dt1 t);;
val t : Set_cookie.New.t = <abstr>

# let dt2 = Set_cookie.New.(find_opt expires t) |> Option.get;;
val dt2 : Date.t = <abstr>

# Date.equal dt1 dt2;;
- : bool = true
```
