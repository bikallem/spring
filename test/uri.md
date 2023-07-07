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
