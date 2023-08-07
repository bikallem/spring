# Uri 

```ocaml
open Spring
```

```ocaml
# #install_printer Uri.pp_path;;
# #install_printer Uri.pp_query;;
# #install_printer Uri.pp_origin_uri;;
# #install_printer Uri.pp_authority;;
# #install_printer Uri.pp_absolute_uri;;
# #install_printer Uri.pp_authority_uri;;
# #install_printer Uri.pp_asterisk_uri;;
# #install_printer Ipaddr.V6.pp;;
# #install_printer Ipaddr.V4.pp;;
# #install_printer Domain_name.pp;;
```

## Path and Query

### make_path

```ocaml
# let p0 = ["path "; "path +:/?#[]@"; "+!$&'()*+,;="];;
val p0 : string list = ["path "; "path +:/?#[]@"; "+!$&'()*+,;="]

# let path0 = Uri.make_path p0;;
val path0 : Uri.path =
  /path%20/path%20%2B%3A%2F%3F%23%5B%5D%40/%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D

# let p1 = [""];;
val p1 : string list = [""]

# let path1 = Uri.make_path p1;;
val path1 : Uri.path = /
```

Empty string at the tail position denotes a trailing `/`.

```ocaml
# Uri.make_path ["hello"; "/"];;
- : Uri.path = /hello/%2F
```

Empty string in any position other than the last is an error.

```ocaml
# Uri.make_path ["hello"; ""; "a"];;
Exception: Invalid_argument "[l] contains empty path segment at index 1".
```

### encode_path

```ocaml
# Uri.encode_path path0;; 
- : string =
"/path%20/path%20%2B%3A%2F%3F%23%5B%5D%40/%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D"

# Uri.encode_path path1;;
- : string = "/"
```

### path_segments

```ocaml
# let p0' = Uri.path_segments path0;;
val p0' : string list = ["path "; "path +:/?#[]@"; "+!$&'()*+,;="]

# p0 = p0';;
- : bool = true

# let p1' = Uri.path_segments path1;;
val p1' : string list = [""]

# p1 = p1';;
- : bool = true
```

### make_query

URI reserved characters are percent encoded.

```ocaml
# let nv0 = ["field +:/?#[]@", "value+!$&'()*+,;="; "hello", "world"];;
val nv0 : (string * string) list =
  [("field +:/?#[]@", "value+!$&'()*+,;="); ("hello", "world")]

# let q0 = Uri.make_query nv0;; 
val q0 : Uri.query =
  field%20%2B%3A%2F%3F%23%5B%5D%40=value%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D&hello=world

# let nv1 = ["field1","value2";"field2","value2"];;
val nv1 : (string * string) list =
  [("field1", "value2"); ("field2", "value2")]

# let q1 = Uri.make_query nv1;;
val q1 : Uri.query = field1=value2&field2=value2

# let nv2 = ["field1", "value1"];;
val nv2 : (string * string) list = [("field1", "value1")]

# let q2 = Uri.make_query nv2;;
val q2 : Uri.query = field1=value1
```

### query_name_values

```ocaml
# let nv0' = Uri.query_name_values q0;;
val nv0' : (string * string) list =
  [("field +:/?#[]@", "value+!$&'()*+,;="); ("hello", "world")]

# nv0 = nv0';;
- : bool = true

# let nv1' = Uri.query_name_values q1;;
val nv1' : (string * string) list =
  [("field1", "value2"); ("field2", "value2")]

# nv1 = nv1';;
- : bool = true

# let nv2' = Uri.query_name_values q2;;
val nv2' : (string * string) list = [("field1", "value1")]

# nv2 = nv2';;
- : bool = true
```

### pct_encode

```ocaml
# Uri.pct_encode ~query:q0 path0;;
- : string =
"/path%20/path%20%2B%3A%2F%3F%23%5B%5D%40/%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D?field%20%2B%3A%2F%3F%23%5B%5D%40=value%2B%21%24%26%27%28%29%2A%2B%2C%3B%3D&hello=world"

# Uri.pct_encode ~query:q1 path1;;
- : string = "/?field1=value2&field2=value2"

# Uri.pct_encode path1;;
- : string = "/"
```

### origin_uri

```ocaml
# let ouri0 = Uri.origin_uri "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd";;
val ouri0 : Uri.origin_uri =
  {
    Path:
     /home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A;
    Query: a=23/?&b=/?dd
  }

# let ouri1 = Uri.origin_uri "/where?q=now";;
val ouri1 : Uri.origin_uri = {
                               Path: /where;
                               Query: q=now
                             }
```

`/` is a valid absolute path.

```ocaml
# let ouri2 = Uri.origin_uri "/";;
val ouri2 : Uri.origin_uri = {
                               Path: /;
                               Query:
                             }
```

Parse trailing '/'.

```ocaml
# Uri.origin_uri "/home/about/";;
- : Uri.origin_uri = {
                       Path: /home/about/;
                       Query:
                     }
```

### origin_uri_path

```ocaml
# Uri.origin_uri_path ouri0;;
- : Uri.path =
/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A

# Uri.origin_uri_path ouri1;;
- : Uri.path = /where
```

### origin_uri_query

```ocaml
# Uri.origin_uri_query ouri0;;
- : Uri.query option = Some a=23/?&b=/?dd

# Uri.origin_uri_query ouri1;;
- : Uri.query option = Some q=now
```

### make_authority

```ocaml
# let auth0 = Uri.make_authority ~port:8080 @@ `IPv4 (Ipaddr.V4.of_string_exn "192.168.0.1");;
val auth0 : Uri.authority = IPv4 192.168.0.1:8080

# let auth1 = Uri.make_authority ~port:8080 @@ `IPv6 (Ipaddr.V6.of_string_exn "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]");;
val auth1 : Uri.authority = IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1:8080

# let auth2 = Uri.make_authority ~port:3000 @@ `Domain_name (Domain_name.of_string_exn "www.example.com");;
val auth2 : Uri.authority = Domain www.example.com:3000
```

### authority 

```ocaml
# let auth00 = Uri.authority "192.168.0.1:8080";;
val auth00 : Uri.authority = IPv4 192.168.0.1:8080

# let auth11 = Uri.authority "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]:8080";;
val auth11 : Uri.authority = IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1:8080

# let auth22 = Uri.authority "www.example.com:3000";;
val auth22 : Uri.authority = Domain www.example.com:3000
```

### authority_host

```ocaml
# Uri.authority_host auth0;;
- : Uri.host = `IPv4 192.168.0.1

# Uri.authority_host auth1;;
- : Uri.host = `IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1
```

### authority_port

```ocaml
# Uri.authority_port auth0;;
- : int option = Some 8080

# Uri.authority_port auth1;;
- : int option = Some 8080
```

### absolute_uri

```ocaml
# let abs0 = Uri.absolute_uri "http://example.com:80";;
val abs0 : Uri.absolute_uri =
  {
    Scheme: http;
    Authority: Domain example.com:80;
    Path: /;
    Query:
  }
```

Parse scheme, authority, path and query.

```ocaml
# let abs1 = Uri.absolute_uri "https://www.example.org/pub/WWW/TheProject.html?a=v1&b=v2";;
val abs1 : Uri.absolute_uri =
  {
    Scheme: https;
    Authority: Domain www.example.org:;
    Path: /pub/WWW/TheProject.html;
    Query: a=v1&b=v2
  }
```

Path ending in `/` is also valid.

```ocaml
# let abs2 = Uri.absolute_uri "https://www.example.com/pub/WWW/";;
val abs2 : Uri.absolute_uri =
  {
    Scheme: https;
    Authority: Domain www.example.com:;
    Path: /pub/WWW/;
    Query:
  }
```

### absolute_uri_scheme

```ocaml
# Uri.absolute_uri_scheme abs0;;
- : Uri.scheme = `Http

# Uri.absolute_uri_scheme abs1;;
- : Uri.scheme = `Https

# Uri.absolute_uri_scheme abs2;;
- : Uri.scheme = `Https
```

### absolute_uri_path_and_query

```ocaml
# Uri.absolute_uri_path_and_query abs0;;
- : Uri.path * Uri.query option = (/, None)

# Uri.absolute_uri_path_and_query abs1;;
- : Uri.path * Uri.query option = (/pub/WWW/TheProject.html, Some a=v1&b=v2)

# Uri.absolute_uri_path_and_query abs2;;
- : Uri.path * Uri.query option = (/pub/WWW/, None)
```

### host_and_port

```ocaml
# Uri.host_and_port abs0;;
- : Uri.host * int option = (`Domain_name example.com, Some 80)

# Uri.host_and_port abs1;;
- : Uri.host * int option = (`Domain_name www.example.org, None)

# Uri.host_and_port abs2;;
- : Uri.host * int option = (`Domain_name www.example.com, None)
```

### authority_uri

```ocaml
# Uri.authority_uri "www.example.com:80" ;;
- : Uri.authority_uri = Domain www.example.com:80

# Uri.authority_uri "192.168.0.1:80";;
- : Uri.authority_uri = IPv4 192.168.0.1:80

# Uri.authority_uri "[2001:0db8:0000:0000:0000:ff00:0042:8329]:8080";;
- : Uri.authority_uri = IPv6 2001:db8::ff00:42:8329:8080
```

### asterisk_uri

```ocaml
# Uri.asterisk_uri "*";;
- : Uri.asterisk_uri = *
```
