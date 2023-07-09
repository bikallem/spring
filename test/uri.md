# Uri 

```ocaml
open Spring
```

## origin

```ocaml
# Uri1.origin @@ Eio.Buf_read.of_string "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd"
  |> Eio.traceln "%a" Uri1.pp_origin;;
+{
+  Path: /home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A;
+  Query: a=23/?&b=/?dd
+}
- : unit = ()

# Uri1.origin @@ Eio.Buf_read.of_string "/where?q=now"
  |> Eio.traceln "%a" Uri1.pp_origin;;
+{
+  Path: /where;
+  Query: q=now
+}
- : unit = ()
```

`/` is a valid absolute path.

```ocaml
# Uri1.origin @@ Eio.Buf_read.of_string "/"
  |> Eio.traceln "%a" Uri1.pp_origin;;
+{
+  Path: /;
+  Query:
+}
- : unit = ()
```

`origin` needs at least one path segment.

```ocaml
# Uri1.origin @@ Eio.Buf_read.of_string ""
Exception: End_of_file.
```

## authority 

```ocaml
# Uri1.authority @@ Eio.Buf_read.of_string "192.168.0.1:8080"
  |> Eio.traceln "%a" Uri1.pp_authority;;
+IPv4 192.168.0.1: 8080
- : unit = ()

# Uri1.authority @@ Eio.Buf_read.of_string "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]:8080"
  |> Eio.traceln "%a" Uri1.pp_authority;;
+IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1: 8080
- : unit = ()
```

## absolute_form

```ocaml
# Uri1.absolute_form @@ Eio.Buf_read.of_string "http://example.com:80"
  |> Eio.traceln "%a" Uri1.pp_absolute_form ;;
+{
+  Scheme: http;
+  Authority: Domain example.com: 80;
+  Path: /;
+  Query:
+}
- : unit = ()
```

Parse scheme, authority, path and query.

```ocaml
# Uri1.absolute_form @@ Eio.Buf_read.of_string "https://www.example.org/pub/WWW/TheProject.html?a=v1&b=v2"
  |> Eio.traceln "%a" Uri1.pp_absolute_form ;;
+{
+  Scheme: https;
+  Authority: Domain www.example.org: ;
+  Path: /pub/WWW/TheProject.html;
+  Query: a=v1&b=v2
+}
- : unit = ()
```

Path ending in `/` is also valid.

```ocaml
# Uri1.absolute_form @@ Eio.Buf_read.of_string "https://www.example.com/pub/WWW/"
  |> Eio.traceln "%a" Uri1.pp_absolute_form ;;
+{
+  Scheme: https;
+  Authority: Domain www.example.com: ;
+  Path: /pub/WWW/;
+  Query:
+}
- : unit = ()
```

## authority_form

```ocaml
# Uri1.authority_form @@ Eio.Buf_read.of_string "www.example.com:80"
  |> Eio.traceln "%a" Uri1.pp_authority_form;;
+Domain www.example.com:80
- : unit = ()

# Uri1.authority_form @@ Eio.Buf_read.of_string "192.168.0.1:80"
  |> Eio.traceln "%a" Uri1.pp_authority_form;;
+IPv4 192.168.0.1:80
- : unit = ()
```

## asterisk_form

```ocaml
# Uri1.asterisk_form @@ Eio.Buf_read.of_string "*";;
- : char = '*'

# Uri1.asterisk_form @@ Eio.Buf_read.of_string "a";;
Exception: Failure "Expected '*' but got 'a'".
```
