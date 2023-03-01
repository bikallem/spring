# Oml tests

```ocaml
module P = Oml__Parser
let () = Printexc.record_backtrace true;
```

## Oml.skip_ws

```ocaml
# let i = P.string_input "\t \n\r <hello";;
val i : P.input = <obj>

# P.skip_ws i;;
- : unit = ()

# i#c;;
- : char = '<'
```

## Oml.start_tag

```ocaml
# let i = P.string_input "\t \n\r <hello    >";;
val i : P.input = <obj>

# P.element i;;
- : string = "hello"
```

let _exp1 () = element ~children:[ text "hello<&"; element "div" ] "div"

