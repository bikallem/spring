# Uri 

```ocaml
open Spring
```

## segment

`segment` must parse all characters in `s` as they are all allowed as per. the syntax.

```ocaml
let s = "asdaszfAASDFASDGDDZ0123456789-._~!$&'()*+,;=:%AF%9A"
```

```ocaml
# Uri1.(segment (Eio.Buf_read.of_string "path1/"));;
- : string = "path1"

# Uri1.(segment @@ Eio.Buf_read.of_string s) = s;;
- : bool = true
```
