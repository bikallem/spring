# Uri 

```ocaml
open Spring
```

## origin_form

```ocaml
let pp_origin_form (path, query) =
  List.iter
```

```ocaml
# Uri1.origin_form @@ Eio.Buf_read.of_string "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd";;
- : Uri1.absolute_path * string option =
(["home"; "hello"; "world";
  "asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A"],
 Some "a=23/?&b=/?dd")

# Uri1.origin_form @@ Eio.Buf_read.of_string "/where?q=now";;
- : Uri1.absolute_path * string option = (["where"], Some "q=now")
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
- : Uri1.scheme * Uri1.authority = (`Http, (`Domain_name <abstr>, Some 80))
```
