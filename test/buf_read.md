# Spring.Buf_read

```ocaml
open Spring

module Buf_read = Spring__Buf_read

let b s = Buf_read.of_string s
```

## Buf_read.quoted_pair

```ocaml
# Buf_read.quoted_pair @@ b {|\"|} ;;
- : char = '"'

# Buf_read.quoted_pair @@ b {|\\|} ;;
- : char = '\\'

# Buf_read.quoted_pair @@ b {|\v|} ;;
- : char = 'v'
```
