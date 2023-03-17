# Oml tests

```ocaml
open Ohtml

let () = Printexc.record_backtrace true

module P = Ohtml__Parser
let pp = new Node.pp

let gen f = 
  let fname = "func1" in
  Out_channel.with_open_gen [Open_wronly; Open_creat;Open_trunc; Open_text] 0o644 (fname ^ ".ml")
    (fun out -> 
      let ssr = new Node.ssr (Out_channel.output_string out) fname in
      f ssr);
  In_channel.with_open_text (fname ^ ".ml")
    (fun in_ch -> Eio.traceln "%s" @@ In_channel.input_all in_ch)
```

## Oml.element

## Normal HTML element.

```ocaml
# let i = P.string_input "\t \n\r <div    ></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# gen (P.doc i);;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<div";
+Buffer.add_string b ">";
+Buffer.add_string b "</div>"
- : unit = ()

# let i = P.string_input "\t \n\r <div   />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# gen (P.doc i);;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<div";
+Buffer.add_string b ">";
+Buffer.add_string b "</div>"
- : unit = ()
```

## Void element (must close with '/>' or '>').

```ocaml
# let i = P.string_input "\t \n\r <area />";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# gen (P.doc i);;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<area";
+Buffer.add_string b ">";
+Buffer.add_string b "</area>"
- : unit = ()

# let i = P.string_input "\t \n\r <area></area>";;
val i : P.input =
  {P.buf = <abstr>; line = 2; col = 4; c = '<'; tok = P.SPACE; i = <fun>}

# gen (P.doc i);;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<area";
+Buffer.add_string b ">";
+Buffer.add_string b "</area>"
- : unit = ()
```

## Element with children.

```ocaml
# let i = P.string_input "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.START_ELEM;
   i = <fun>}

# gen (P.doc i);;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<div";
+Buffer.add_string b ">";
+Buffer.add_string b "<span";
+Buffer.add_string b ">";
+Buffer.add_string b "<area";
+Buffer.add_string b ">";
+Buffer.add_string b "</area>"
+Buffer.add_string b "</span>"
+Buffer.add_string b "<span";
+Buffer.add_string b ">";
+Buffer.add_string b "<area";
+Buffer.add_string b ">";
+Buffer.add_string b "</area>"
+Buffer.add_string b "</span>"
+Buffer.add_string b "<span";
+Buffer.add_string b ">";
+Buffer.add_string b "<area";
+Buffer.add_string b ">";
+Buffer.add_string b "</area>"
+Buffer.add_string b "</span>"
+Buffer.add_string b "</div>"
- : unit = ()
```

## Element with code-block children.

```ocaml
# let i = P.string_input {|<div>{Node.html_text "hello"}<span><area/></span></div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.START_ELEM;
   i = <fun>}

# gen @@ P.doc i;;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<div";
+Buffer.add_string b ">";
+(fun b -> Node.html_text "hello" ) b;
+Buffer.add_string b "<span";
+Buffer.add_string b ">";
+Buffer.add_string b "<area";
+Buffer.add_string b ">";
+Buffer.add_string b "</area>"
+Buffer.add_string b "</span>"
+Buffer.add_string b "</div>"
- : unit = ()
```

## Code element with HTML mixed inside code-block.

```ocaml
# let i = P.string_input "<div>{ List.iter (fun a -> <section>{Oml.Node.html_text a}</section>) names}</div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.START_ELEM;
   i = <fun>}

# gen @@ P.doc i;;
+let func1 : Node.html_writer =
+fun b ->
+Buffer.add_string b "<div";
+Buffer.add_string b ">";
+(fun b ->  List.iter (fun a ->
+Buffer.add_string b "<section";
+Buffer.add_string b ">";
+(fun b -> Oml.Node.html_text a ) b;
+Buffer.add_string b "</section>") names ) b;
+Buffer.add_string b "</div>"
- : unit = ()
```

## Text element

```ocaml
# let i = P.string_input {|<div>    <span>Hello World</span>Hello &Again!</div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string = "<div><span>Hello World</span>Hello &Again!</div>"
```

## Comment element

```ocaml
# let i = P.string_input {|<div> Hello     <!-- hello comment -->    <span>Hello World</span>Hello &Again!</div>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string =
"<div>Hello <!-- hello comment --><span>Hello World</span>Hello &Again!</div>"
```

## Bool attributes

```ocaml
# let i = P.string_input "<input disabled attr1 attr2 attr3></input>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string = "<input disabled attr1 attr2 attr3></input>"
```

## Unquoted attribute value

```ocaml
# let i = P.string_input "<input attr1 = attrv></input>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string = "<input attr1=attrv></input>"
```

## Quoted attribute value

```ocaml
# let i = P.string_input {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string =
"<input disabled attr1='value1' attr2=\"val2\" attr3=val3><span></span></input>"
```

## Code attribute value

```ocaml
# let i = P.string_input {|<input disabled attr1={"value1"} attr2 = { string_of_int 100 } >  </input>|};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string =
"<input disabled attr1={\"value1\"} attr2={ string_of_int 100 }></input>"
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# let i = P.string_input {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100} ></input> |};;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'i'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string =
"<input disabled {Spring_oml.attribute \"name\" \"value\"} attr1='value1' attr2=\"val2\" attr3=val3 attr4={ string_of_int 100}></input>"
```

## Element with comments.

```ocaml
# let i = P.string_input "<div><a></a><a></a><a></a></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'd'; tok = P.START_ELEM;
   i = <fun>}

# P.doc i @@ pp;;
- : string = "<div><a></a><a></a><a></a></div>"
```

## @param

```ocaml
# let i = P.string_input "@params a:int b:string\n<div>Hello <span>world!</span></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'p'; tok = P.DATA '@'; i = <fun>}

# P.doc i @@ pp;;
- : string = "@params a:int b:string\n<div>Hello <span>world!</span></div>"
```
