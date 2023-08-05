# Uri 

```ocaml
open Spring
```

## make_path

```ocaml
# Uri.make_path ["path "; "path +:/?#[]@"; "+!$&'()*+,;="];;
- : Uri.path =
["/path%20"; "/path%20%2B%3A%2F%3F%23%5B%5D%40";
 "/%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D"]
```

## make_query

URI reserved characters are percent encoded.

```ocaml
# Uri.make_query ["field +:/?#[]@", "value+!$&'()*+,;="; "hello", "world"];;
- : Uri.query =
"field%20%2B%3A%2F%3F%23%5B%5D%40=value%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D&hello=world"

# Uri.make_query ["field1","value2";"field2","value2"];;
- : Uri.query = "field1=value2&field2=value2"
```

## origin_uri

```ocaml
# Uri.origin_uri "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd"
  |> Eio.traceln "%a" Uri.pp_origin_uri;;
+{
+  Path: /home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A;
+  Query: a=23/?&b=/?dd
+}
- : unit = ()

# Uri.origin_uri "/where?q=now"
  |> Eio.traceln "%a" Uri.pp_origin_uri;;
+{
+  Path: /where;
+  Query: q=now
+}
- : unit = ()
```

`/` is a valid absolute path.

```ocaml
# Uri.origin_uri "/"
  |> Eio.traceln "%a" Uri.pp_origin_uri;;
+{
+  Path: /;
+  Query:
+}
- : unit = ()
```

## authority 

```ocaml
# Uri.authority "192.168.0.1:8080"
  |> Eio.traceln "%a" Uri.pp_authority;;
+IPv4 192.168.0.1:8080
- : unit = ()

# Uri.authority "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]:8080"
  |> Eio.traceln "%a" Uri.pp_authority;;
+IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1:8080
- : unit = ()
```

## absolute_uri

```ocaml
# Uri.absolute_uri "http://example.com:80"
  |> Eio.traceln "%a" Uri.pp_absolute_uri ;;
+{
+  Scheme: http;
+  Authority: Domain example.com:80;
+  Path: /;
+  Query:
+}
- : unit = ()
```

Parse scheme, authority, path and query.

```ocaml
# Uri.absolute_uri "https://www.example.org/pub/WWW/TheProject.html?a=v1&b=v2"
  |> Eio.traceln "%a" Uri.pp_absolute_uri ;;
+{
+  Scheme: https;
+  Authority: Domain www.example.org:;
+  Path: /pub/WWW/TheProject.html;
+  Query: a=v1&b=v2
+}
- : unit = ()
```

Path ending in `/` is also valid.

```ocaml
# Uri.absolute_uri "https://www.example.com/pub/WWW/"
  |> Eio.traceln "%a" Uri.pp_absolute_uri ;;
+{
+  Scheme: https;
+  Authority: Domain www.example.com:;
+  Path: /pub/WWW/;
+  Query:
+}
- : unit = ()
```

## authority_uri

```ocaml
# Uri.authority_uri "www.example.com:80" 
  |> Eio.traceln "%a" Uri.pp_authority_uri;;
+Domain www.example.com:80
- : unit = ()

# Uri.authority_uri "192.168.0.1:80"
  |> Eio.traceln "%a" Uri.pp_authority_uri;;
+IPv4 192.168.0.1:80
- : unit = ()

# Uri.authority_uri "[2001:0db8:0000:0000:0000:ff00:0042:8329]:8080"
  |> Eio.traceln "%a" Uri.pp_authority_uri;;
+IPv6 2001:db8::ff00:42:8329:8080
- : unit = ()
```

## asterisk_uri

```ocaml
# Uri.asterisk_uri "*"
  |> Eio.traceln "%a" Uri.pp_asterisk_uri;;
+*
- : unit = ()
```
