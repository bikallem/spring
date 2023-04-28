# Router tests

```ocaml
open Router_test
open Spring

let () = Printexc.record_backtrace true
```

```ocaml
# pp_match Method.get "/public/css/style.css";;
"file path: css/style.css"
- : unit = ()
```
