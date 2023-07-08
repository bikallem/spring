# Uri 

```ocaml
open Spring
```

## origin_form

```ocaml
# Uri1.origin_form @@ Eio.Buf_read.of_string "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd";;
- : Uri1.absolute_path * string option =
(["home"; "hello"; "world";
  "asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A"],
 Some "a=23/?&b=/?dd")

# Uri1.origin_form @@ Eio.Buf_read.of_string "/where?q=now";;
- : Uri1.absolute_path * string option = (["where"], Some "q=now")
```

`/` is a valid absolute path.

```ocaml
# Uri1.origin_form @@ Eio.Buf_read.of_string "/";;
- : Uri1.absolute_path * string option = ([""], None)
```

`origin_form` needs at least one path segment.

```ocaml
# Uri1.origin_form @@ Eio.Buf_read.of_string "";;
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
# Uri1.absolute_form @@ Eio.Buf_read.of_string "http://example.com:80";;
- : Uri1.scheme * Uri1.authority * Uri1.absolute_path * string option =
(`Http, (`Domain_name <abstr>, Some 80), [], None)
```

Parse scheme, authority, path and query.

```ocaml
# Uri1.absolute_form @@ Eio.Buf_read.of_string "https://www.example.org/pub/WWW/TheProject.html?a=v1&b=v2";;
- : Uri1.scheme * Uri1.authority * Uri1.absolute_path * string option =
(`Https, (`Domain_name <abstr>, None), ["pub"; "WWW"; "TheProject.html"],
 Some "a=v1&b=v2")
```

## authority_form

```ocaml
# Uri1.authority_form @@ Eio.Buf_read.of_string "www.example.com:80";;
- : Uri1.host * int = (`Domain_name <abstr>, 80)

# Uri1.authority_form @@ Eio.Buf_read.of_string "192.168.0.1:80";;
- : Uri1.host * int = (`IPv4 (Ipaddr.V4 <abstr>), 80)
```
