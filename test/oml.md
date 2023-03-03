# Oml tests

```ocaml
open Oml

let () = Printexc.record_backtrace true

module P = Oml__Parser
let html = new Node.html 
```

## Oml.root 

normal element.

```ocaml
# let i = P.string_input "\t \n\r <div    ></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ html ;;
- : string = "<div></div>"
```

Void element (must close with '/>' or '>').

```ocaml
# let i = P.string_input "\t \n\r <area />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'a'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ html;;
- : string = "<area/>"

# let i = P.string_input "\t \n\r <area >";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'a'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ html;;
- : string = "<area/>"
```

Element with children.

```ocaml
# let i = P.string_input "\t \n\r <div><span><area/></span></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ html;;
- : string = "<div><span><area/></span></div>"
```

Element with code-block children.

```ocaml
# let i = P.string_input {|<div>{Node.text "hello"}</div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ html;;
- : string = "<div>{Node.text \"hello\"}</div>"
```

Element with html mixed inside code-block.

```ocaml
# let i = P.string_input "<div>{ List.map (fun a -> <section>{Gilung_oml.text a}</section>) names }</div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ html;;
- : string =
"<div>{ List.map (fun a -> <section>{Gilung_oml.text a}</section>) names }</div>"
```
