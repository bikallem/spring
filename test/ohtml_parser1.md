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
# Ohtml.parse_element "\t \n\r <div></div>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = []; children = []}}

# Ohtml.parse_element "<div />";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = []; children = []}}
```

## Element with children.

```ocaml
# Ohtml.parse_element "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Node2.Element
           {Ohtml__.Node2.tag_name = "area"; attributes = []; children = []}]};
      Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Node2.Element
           {Ohtml__.Node2.tag_name = "area"; attributes = []; children = []}]};
      Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Node2.Element
           {Ohtml__.Node2.tag_name = "area"; attributes = []; children = []}]}]}}
```

## Element with code-block children.

```ocaml
# Ohtml.parse_element {|<div>{Node.text "hello"}<span>    <area/></span></div>|};;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Node2.Code_block "Node.text \"hello\"";
      Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Node2.Element
           {Ohtml__.Node2.tag_name = "area"; attributes = []; children = []}]}]}}
```

## Code element with HTML mixed inside code-block.

```ocaml
# Ohtml.parse_element "<div>{ List.map (fun a -> }<section>{Ohtml.text a}</section>{) names }</div>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Node2.Code_block " List.map (fun a -> ";
      Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "section"; attributes = [];
        children = [Ohtml__.Node2.Code_block "Ohtml.text a"]};
      Ohtml__.Node2.Code_block ") names "]}}
```

## Bool attributes

```ocaml
# Ohtml.parse_element "<input disabled attr1 attr2 attr3></input>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "input";
    attributes =
     [Ohtml__.Node2.Bool_attribute "disabled";
      Ohtml__.Node2.Bool_attribute "attr1";
      Ohtml__.Node2.Bool_attribute "attr2";
      Ohtml__.Node2.Bool_attribute "attr3"];
    children = []}}
```

## Unquoted attribute value

```ocaml
# Ohtml.parse_element "<input attr1 = attrv\n></input>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "input";
    attributes = [Ohtml__.Node2.Name_val_attribute ("attr1", "attrv")];
    children = []}}
```

## Quoted attribute value

```ocaml
# Ohtml.parse_element {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "input";
    attributes =
     [Ohtml__.Node2.Bool_attribute "disabled";
      Ohtml__.Node2.Name_val_attribute ("attr1", "value1");
      Ohtml__.Node2.Name_val_attribute ("attr2", "val2");
      Ohtml__.Node2.Name_val_attribute ("attr3", "val3")];
    children =
     [Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = []; children = []}]}}
```

## Code attribute value

```ocaml
# Ohtml.parse_element {|<input attr1=  {"value1"} attr2 = { string_of_int 100 }></input>|};;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "input";
    attributes =
     [Ohtml__.Node2.Name_code_val_attribute ("attr1", "\"value1\"");
      Ohtml__.Node2.Name_code_val_attribute ("attr2", " string_of_int 100 ")];
    children = []}}
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# Ohtml.parse_element {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100} ></input> |};;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "input";
    attributes =
     [Ohtml__.Node2.Bool_attribute "disabled";
      Ohtml__.Node2.Code_attribute "Spring_oml.attribute \"name\" \"value\"";
      Ohtml__.Node2.Name_val_attribute ("attr1", "value1");
      Ohtml__.Node2.Name_val_attribute ("attr2", "val2");
      Ohtml__.Node2.Name_val_attribute ("attr3", "val3");
      Ohtml__.Node2.Name_code_val_attribute ("attr4", " string_of_int 100")];
    children = []}}
```

## HTML Comment

```ocaml
# Ohtml.parse_element "<!-- Hello world comment -->";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root = Ohtml__.Node2.Html_comment " Hello world comment "}

# Ohtml.parse_element "<![ Hello world conditional comment ]>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Html_conditional_comment " Hello world conditional comment "}
```

## HTML CDATA

```ocaml
# Ohtml.parse_element "<![CDATA[ This is CDATA ]]>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root = Ohtml__.Node2.Cdata " This is CDATA "}
```

## HTML DTD

```ocaml
# Ohtml.parse_element "<!DOCTYPE html><html></html>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = Some "DOCTYPE html";
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "html"; attributes = []; children = []}}

# Ohtml.parse_element "<!doctype html><html></html>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = Some "doctype html";
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "html"; attributes = []; children = []}}
```

## Text element

```ocaml
# Ohtml.parse_element "<div>  <span>\n\t Hello World { \"hello world from OCaml!\"}    </span>     Hello &Again!     </div>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = None; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Node2.Html_text "Hello World ";
          Ohtml__.Node2.Code_block " \"hello world from OCaml!\""]};
      Ohtml__.Node2.Html_text "Hello &Again!     "]}}
```

## @param

```ocaml
# Ohtml.parse_doc "fun a:int b:string ->\n<div>Hello <span>world!</span></div>";;
- : Node2.doc =
{Ohtml__.Node2.fun_args = Some "a:int b:string "; dtd = None;
 root =
  Ohtml__.Node2.Element
   {Ohtml__.Node2.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Node2.Html_text "Hello ";
      Ohtml__.Node2.Element
       {Ohtml__.Node2.tag_name = "span"; attributes = [];
        children = [Ohtml__.Node2.Html_text "world!"]}]}}
```
