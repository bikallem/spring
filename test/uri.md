# Uri 

```ocaml
open Spring
```

## absolute_path

```ocaml
# Uri1.absolute_path @@ Eio.Buf_read.of_string "/home/hello/world/asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A";;
- : string list =
["home"; "hello"; "world";
 "asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A"]
```

## origin_form

```ocaml
# Uri1.origin_form @@ Eio.Buf_read.of_string "/home/hello?a=23/?&b=/?dd";;
- : string list * string option = (["home"; "hello"], Some "a=23/?&b=/?dd")

# Uri1.origin_form @@ Eio.Buf_read.of_string "/where?q=now";;
- : string list * string option = (["where"], Some "q=now")
```
