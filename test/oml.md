# Oml tests

```ocaml
module P = Oml__Parser
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
# let i = P.string_input "\t \n\r <hello ";;
val i : P.input = <obj>

# P.start_tag i;;
- : string = "hello"

# i#c;;
- : char = ' '
```

let _exp1 () = element ~children:[ text "hello<&"; element "div" ] "div"

