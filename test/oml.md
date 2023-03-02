# Oml tests

```ocaml
module P = Oml__Parser
let () = Printexc.record_backtrace true;
```

## Oml.root 

normal element.

```ocaml
# let i = P.string_input "\t \n\r <div    ></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.element i;;
- : string = "div"
```

Void element (must close with '/>' or '>').

```ocaml
# let i = P.string_input "\t \n\r <area />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'a'; tok = P.Start_elem;
   i = <fun>}

# P.element i;;
- : string = "area"

# let i = P.string_input "\t \n\r <area >";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'a'; tok = P.Start_elem;
   i = <fun>}

# P.element i;;
- : string = "area"
```

Element with children.

```ocaml
# let i = P.string_input "\t \n\r <div></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.element i;;
- : string = "div"
```

let _exp1 () = element ~children:[ text "hello<&"; element "div" ] "div"

