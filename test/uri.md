# Uri 

```ocaml
open Spring
```

## make_path

```ocaml
# Uri1.make_path ["path "; "path +:/?#[]@"; "+!$&'()*+,;="];;
- : Uri1.path =
["/path%20"; "/path%20%2B%3A%2F%3F%23%5B%5D%40";
 "/%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D"]
```

## make_query

URI reserved characters are percent encoded.

```ocaml
# Uri1.make_query ["field +:/?#[]@", "value+!$&'()*+,;="; "hello", "world"];;
- : Uri1.query =
"field%20%2B%3A%2F%3F%23%5B%5D%40=value%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D&hello=world"

# Uri1.make_query ["field1","value2";"field2","value2"];;
- : Uri1.query = "field1=value2&field2=value2"
```

## origin

```ocaml
# Uri1.of_string "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd"
  |> Uri1.origin_form 
  |> Eio.traceln "%a" Uri1.pp;;
+{
+  Path: /home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A;
+  Query: a=23/?&b=/?dd
+}
- : unit = ()

# Uri1.of_string "/where?q=now"
  |> Uri1.origin_form
  |> Eio.traceln "%a" Uri1.pp;;
+{
+  Path: /where;
+  Query: q=now
+}
- : unit = ()
```

`/` is a valid absolute path.

```ocaml
# Uri1.of_string "/"
  |> Uri1.origin_form
  |> Eio.traceln "%a" Uri1.pp;;
+{
+  Path: /;
+  Query:
+}
- : unit = ()
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
# Uri1.of_string "http://example.com:80"
  |> Uri1.absolute_form
  |> Eio.traceln "%a" Uri1.pp ;;
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
# Uri1.of_string "https://www.example.org/pub/WWW/TheProject.html?a=v1&b=v2"
  |> Uri1.absolute_form
  |> Eio.traceln "%a" Uri1.pp ;;
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
# Uri1.of_string "https://www.example.com/pub/WWW/"
  |> Uri1.absolute_form
  |> Eio.traceln "%a" Uri1.pp ;;
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
# let rt = Uri1.of_string "www.example.com:80" |> Uri1.authority_form ;;
val rt : [ `authority ] Uri1.t = <abstr>

# Eio.traceln "%a" Uri1.pp rt;;
+Domain www.example.com:80
- : unit = ()

# Uri1.authority' rt;;
- : Uri1.host * int = (`Domain_name <abstr>, 80)

# Uri1.of_string "192.168.0.1:80"
  |> Uri1.authority_form
  |> Eio.traceln "%a" Uri1.pp;;
+IPv4 192.168.0.1:80
- : unit = ()

# Uri1.of_string "[2001:0db8:0000:0000:0000:ff00:0042:8329]:8080"
  |> Uri1.authority_form
  |> Eio.traceln "%a" Uri1.pp;;
+IPv6 2001:db8::ff00:42:8329:8080
- : unit = ()
```

## asterisk_form

```ocaml
# Uri1.of_string "*"
  |> Uri1.asterisk_form
  |> Eio.traceln "%a" Uri1.pp;;
+*
- : unit = ()
```
