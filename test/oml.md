# Oml tests

```ocaml
module P = Oml__Parser
let () = Printexc.record_backtrace true;
```

## Oml.skip_ws

```ocaml
# let i = P.string_input "\t \n\r <";;
val i : P.input = <obj>

# P.skip_ws i;;
- : unit = ()

# i#c;;
- : char = '\000'
```

## Oml.root 

normal element.

```ocaml
# let i = P.string_input "\t \n\r <div    ></div>";;
val i : P.input = <obj>

# P.root i;;
- : string = "div"
```

Void element (must close with '/>' or '>').

```ocaml
# let i = P.string_input "\t \n\r <area />";;
val i : P.input = <obj>

# P.root i;;
- : string = "area"

# let i = P.string_input "\t \n\r <area >";;
val i : P.input = <obj>

# P.root i;;
- : string = "area"
```

Element with children.

```ocaml
# let i = P.string_input "\t \n\r <div></div>";;
val i : P.input = <obj>

# P.root i;;
- : string = "div"
```

let _exp1 () = element ~children:[ text "hello<&"; element "div" ] "div"

