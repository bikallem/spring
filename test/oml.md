# Oml tests

## Oml.skip_ws

```ocaml
# let i = Oml.string_input "\t \n\r <hello";;
val i : Oml.input = <obj>

# Oml.skip_ws i;;
- : unit = ()

# i#c;;
- : char = '<'
```

## Oml.start_tag

```ocaml
# let i = Oml.string_input "\t \n\r <hello ";;
val i : Oml.input = <obj>

# Oml.start_tag i;;
- : string = "hello"

# i#c;;
- : char = ' '
```

let _exp1 () = element ~children:[ text "hello<&"; element "div" ] "div"
