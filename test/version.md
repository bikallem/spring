# Version tests

```ocaml
open Spring
open Eio
```

## Version.parser

```ocaml
# let r = Buf_read.of_string "HTTP/1.1";;
val r : Buf_read.t = <abstr>

# Version.parse r;;
- : Version.t = (1, 1)

# Version.parse (Buf_read.of_string "HTTP/1.0");;
- : Version.t = (1, 0)
```
