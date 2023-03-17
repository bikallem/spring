# Ohtml tests

```ocaml
open Ohtml

let () = Printexc.record_backtrace true

module P = Ohtml__Parser
let pp = new Node.pp
```

## Ohtml.element

## Normal HTML element.

```ocaml
# Ohtml.parse "\t \n\r <div></div>";;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "div"; attributes = []; children = []}

# Ohtml.parse "<div />";;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "div"; attributes = []; children = []}
```

## Element with children.

```ocaml
# Ohtml.parse "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "div"; attributes = [];
  children =
   [Ohtml.Node2.Element
     {Ohtml.Node2.tag_name = "span"; attributes = [];
      children =
       [Ohtml.Node2.Element
         {Ohtml.Node2.tag_name = "area"; attributes = []; children = []}]};
    Ohtml.Node2.Element
     {Ohtml.Node2.tag_name = "span"; attributes = [];
      children =
       [Ohtml.Node2.Element
         {Ohtml.Node2.tag_name = "area"; attributes = []; children = []}]};
    Ohtml.Node2.Element
     {Ohtml.Node2.tag_name = "span"; attributes = [];
      children =
       [Ohtml.Node2.Element
         {Ohtml.Node2.tag_name = "area"; attributes = []; children = []}]}]}
```

## Element with code-block children.

```ocaml
# Ohtml.parse {|<div>{Node.text "hello"}<span>    <area/></span></div>|};;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "div"; attributes = [];
  children =
   [Ohtml.Node2.Code_block "Node.text \"hello\"";
    Ohtml.Node2.Element
     {Ohtml.Node2.tag_name = "span"; attributes = [];
      children =
       [Ohtml.Node2.Element
         {Ohtml.Node2.tag_name = "area"; attributes = []; children = []}]}]}
```

## Code element with HTML mixed inside code-block.

```ocaml
# Ohtml.parse "<div>{ List.map (fun a -> }<section>{Ohtml.text a}</section>{) names }</div>";;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "div"; attributes = [];
  children =
   [Ohtml.Node2.Code_block " List.map (fun a -> ";
    Ohtml.Node2.Element
     {Ohtml.Node2.tag_name = "section"; attributes = [];
      children = [Ohtml.Node2.Code_block "Ohtml.text a"]};
    Ohtml.Node2.Code_block ") names "]}
```

## Bool attributes

```ocaml
# Ohtml.parse "<input disabled attr1 attr2 attr3></input>";;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "input";
  attributes =
   [Ohtml.Node2.Bool_attribute "disabled";
    Ohtml.Node2.Bool_attribute "attr1"; Ohtml.Node2.Bool_attribute "attr2";
    Ohtml.Node2.Bool_attribute "attr3"];
  children = []}
```

## Unquoted attribute value

```ocaml
# Ohtml.parse "<input attr1 = attrv\n></input>";;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "input";
  attributes = [Ohtml.Node2.Name_val_attribute ("attr1", "attrv")];
  children = []}
```

## Quoted attribute value

```ocaml
# Ohtml.parse {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "input";
  attributes =
   [Ohtml.Node2.Bool_attribute "disabled";
    Ohtml.Node2.Name_val_attribute ("attr1", "value1");
    Ohtml.Node2.Name_val_attribute ("attr2", "val2");
    Ohtml.Node2.Name_val_attribute ("attr3", "val3")];
  children =
   [Ohtml.Node2.Element
     {Ohtml.Node2.tag_name = "span"; attributes = []; children = []}]}
```

## Code attribute value

```ocaml
# Ohtml.parse {|<input attr1=  {"value1"} attr2 = { string_of_int 100 }></input>|};;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "input";
  attributes =
   [Ohtml.Node2.Name_code_val_attribute ("attr1", "\"value1\"");
    Ohtml.Node2.Name_code_val_attribute ("attr2", " string_of_int 100 ")];
  children = []}
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# Ohtml.parse {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100} ></input> |};;
- : Node2.element =
Ohtml.Node2.Element
 {Ohtml.Node2.tag_name = "input";
  attributes =
   [Ohtml.Node2.Bool_attribute "disabled";
    Ohtml.Node2.Code_attribute "Spring_oml.attribute \"name\" \"value\"";
    Ohtml.Node2.Name_val_attribute ("attr1", "value1");
    Ohtml.Node2.Name_val_attribute ("attr2", "val2");
    Ohtml.Node2.Name_val_attribute ("attr3", "val3");
    Ohtml.Node2.Name_code_val_attribute ("attr4", " string_of_int 100")];
  children = []}
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

## @param

```ocaml
# let i = P.string_input "@params a:int b:string\n<div>Hello <span>world!</span></div>";;
val i : P.input =
  {P.buf = <abstr>; line = 1; col = 1; c = 'p'; tok = P.DATA '@'; i = <fun>}

# P.doc i @@ pp;;
- : string = "@params a:int b:string\n<div>Hello <span>world!</span></div>"
```
