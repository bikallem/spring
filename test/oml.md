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
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# P.root i @@ pp ;;
- : string = "<div></div>"

# let i = P.string_input "\t \n\r <div   />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# P.root i @@ pp ;;
- : string = "<div></div>"
```

## Void element (must close with '/>' or '>').

```ocaml
# let i = P.string_input "\t \n\r <area />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# P.root i @@ pp;;
- : string = "<area></area>"

# let i = P.string_input "\t \n\r <area></area>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# P.root i @@ pp;;
- : string = "<area></area>"
```

## Element with children.

```ocaml
# let i = P.string_input "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<div><span><area></area></span><span><area></area></span><span><area></area></span></div>"
```

## Element with code-block children.

```ocaml
# let i = P.string_input {|<div>{Node.text "hello"}<span><area/></span></div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<div>{Node.text \"hello\"}<span><area></area></span></div>"
```

## Code element with HTML mixed inside code-block.

```ocaml
# let i = P.string_input "<div>{ List.map (fun a -> <section>{Gilung_oml.text a}</section>) names }</div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<div>{ List.map (fun a -> <section>{Gilung_oml.text a}</section> names }</div>"
```

## Text element

```ocaml
# let i = P.string_input {|<div>    <span>Hello World</span>Hello &Again!</div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<div><span>Hello World</span>Hello &amp;Again!</div>"
```

## Comment element

```ocaml
# let i = P.string_input {|<div> Hello     <!-- hello comment -->    <span>Hello World</span>Hello &Again!</div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<div>Hello <!-- hello comment --><span>Hello World</span>Hello &amp;Again!</div>"
```

## Bool attributes

```ocaml
# let i = P.string_input "<input disabled attr1 attr2 attr3></input>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<input disabled attr1 attr2 attr3></input>"
```

## Unquoted attribute value

```ocaml
# let i = P.string_input "<input attr1 = attrv></input>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<input attr1=attrv></input>"
```

## Quoted attribute value

```ocaml
# let i = P.string_input {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<input disabled attr1='value1' attr2=\"val2\" attr3=val3><span></span></input>"
```

## Code attribute value

```ocaml
# let i = P.string_input {|<input disabled attr1={"value1"} attr2 = { string_of_int 100 } >  </input>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<input disabled attr1={\"value1\"} attr2={ string_of_int 100 }></input>"
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# let i = P.string_input {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100} ></input> |};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string =
"<input disabled {Spring_oml.attribute \"name\" \"value\"} attr1='value1' attr2=\"val2\" attr3=val3 attr4={ string_of_int 100}></input>"
```

## Element with comments.

```ocaml
# let i = P.string_input "<div><a></a><a></a><a></a></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.Start_elem;
   i = <fun>}

# P.root i @@ pp;;
- : string = "<div><a></a><a></a><a></a></div>"
```
