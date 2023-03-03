# Oml tests

```ocaml
open Oml

let () = Printexc.record_backtrace true

module P = Oml__Parser
let pp = new Node.pp
```

## Oml.element

## Normal HTML element.

```ocaml
# let i = P.string_input "\t \n\r <div    ></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp ;;
- : string = "<div></div>"
```

## Void element (must close with '/>' or '>').

```ocaml
# let i = P.string_input "\t \n\r <area />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'a'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<area/>"

# let i = P.string_input "\t \n\r <area >";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'a'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<area/>"
```

## Element with children.

```ocaml
# let i = P.string_input "\t \n\r <div><span><area/></span></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 5; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<div><span><area/></span></div>"
```

## Element with code-block children.

```ocaml
# let i = P.string_input {|<div>{Node.text "hello"}</div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<div>{Node.text \"hello\"}</div>"
```

## Code element with HTML mixed inside code-block.

```ocaml
# let i = P.string_input "<div>{ List.map (fun a -> <section>{Gilung_oml.text a}</section>) names }</div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<div>{ List.map (fun a -> <section>{Gilung_oml.text a}</section>) names }</div>"
```

## Empty Attributes

Bool attributes.

```ocaml
# let i = P.string_input "<input disabled attr1 attr2 attr3>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<input disabled attr1 attr2 attr3/>"
```

## Name/Value attribute parsing

Name/Value attributes.

```ocaml
# let i = P.string_input {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    >|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<input disabled attr1='value1' attr2='val2' attr3='val3'/>"
```

## Code attribute, name/value attribute parsing

Name/Value attributes.

```ocaml
# let i = P.string_input {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    >|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<input disabled {Spring_oml.attribute \"name\" \"value\"} attr1='value1' attr2='val2' attr3='val3'/>"
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# let i = P.string_input {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100}  >|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 2; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<input disabled {Spring_oml.attribute \"name\" \"value\"} attr1='value1' attr2='val2' attr3='val3' attr4={ string_of_int 100}/>"
```


