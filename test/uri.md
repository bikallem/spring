# Uri 

```ocaml
open Spring
```

## origin_form

```ocaml
# Uri1.origin_form @@ Eio.Buf_read.of_string "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A?a=23/?&b=/?dd";;
- : string list * string option =
(["home"; "hello"; "world";
  "asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A"],
 Some "a=23/?&b=/?dd")

# Uri1.origin_form @@ Eio.Buf_read.of_string "/where?q=now";;
- : string list * string option = (["where"], Some "q=now")
```

## host 

```ocaml
let pp_host = function
  | `IPv4 addr -> Eio.traceln "IPv4 %a" Ipaddr.pp addr
  | `IPv6 addr -> Eio.traceln "IPv6 %a" Ipaddr.pp addr
  | `Domain_name dn -> Eio.traceln "Domain name: %a" Domain_name.pp dn
```

```ocaml
# Uri1.host @@ Eio.Buf_read.of_string "192.168.0.1" |> pp_host;;
+IPv4 192.168.0.1
- : unit = ()

# Uri1.host @@ Eio.Buf_read.of_string "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]" |> pp_host;;
+IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1
- : unit = ()
```

## absolute_form

```ocaml
# Uri1.absolute_form @@ Eio.Buf_read.of_string "http://example.com:80";;
- : Uri1.scheme * Uri1.authority = (`Http, (`Domain_name <abstr>, Some 80))
```
