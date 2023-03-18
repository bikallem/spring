# Ohtml tests

```ocaml
open Ohtml

let () = Printexc.record_backtrace true
```

## Ohtml.element

## Normal HTML element.

```ocaml
# Ohtml.parse_element "\t \n\r <div></div>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "div"; attributes = []; children = []}}

# Ohtml.parse_element "<div />";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "div"; attributes = []; children = []}}
```

## Element with children.

```ocaml
# Ohtml.parse_element "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Doc.Element
           {Ohtml__.Doc.tag_name = "area"; attributes = []; children = []}]};
      Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Doc.Element
           {Ohtml__.Doc.tag_name = "area"; attributes = []; children = []}]};
      Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Doc.Element
           {Ohtml__.Doc.tag_name = "area"; attributes = []; children = []}]}]}}
```

## Element with code-block children.

```ocaml
# Ohtml.parse_element {|<div>{{Node.text "hello"} <span id="v" disabled>{Node.text "world"}<span></span></span> } <span>    <area/></span></div>|};;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Doc.Code
       [Ohtml__.Doc.Code_block "Node.text \"hello\"";
        Ohtml__.Doc.Code_element
         {Ohtml__.Doc.tag_name = "span";
          attributes =
           [Ohtml__.Doc.Name_val_attribute ("id", "v");
            Ohtml__.Doc.Bool_attribute "disabled"];
          children =
           [Ohtml__.Doc.Code_block "Node.text \"world\"";
            Ohtml__.Doc.Code_element
             {Ohtml__.Doc.tag_name = "span"; attributes = []; children = []}]}];
      Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Doc.Element
           {Ohtml__.Doc.tag_name = "area"; attributes = []; children = []}]}]}}
```

## Bool attributes

```ocaml
# Ohtml.parse_element "<input disabled attr1 attr2 attr3></input>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "input";
    attributes =
     [Ohtml__.Doc.Bool_attribute "disabled";
      Ohtml__.Doc.Bool_attribute "attr1"; Ohtml__.Doc.Bool_attribute "attr2";
      Ohtml__.Doc.Bool_attribute "attr3"];
    children = []}}
```

## Unquoted attribute value

```ocaml
# Ohtml.parse_element "<input attr1 = attrv\n></input>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "input";
    attributes = [Ohtml__.Doc.Name_val_attribute ("attr1", "attrv")];
    children = []}}
```

## Quoted attribute value

```ocaml
# Ohtml.parse_element {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "input";
    attributes =
     [Ohtml__.Doc.Bool_attribute "disabled";
      Ohtml__.Doc.Name_val_attribute ("attr1", "value1");
      Ohtml__.Doc.Name_val_attribute ("attr2", "val2");
      Ohtml__.Doc.Name_val_attribute ("attr3", "val3")];
    children =
     [Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = []; children = []}]}}
```

## Code attribute value

```ocaml
# Ohtml.parse_element {|<input attr1=  {"value1"} attr2 = { string_of_int 100 }></input>|};;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "input";
    attributes =
     [Ohtml__.Doc.Name_code_val_attribute ("attr1", "\"value1\"");
      Ohtml__.Doc.Name_code_val_attribute ("attr2", " string_of_int 100 ")];
    children = []}}
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# Ohtml.parse_element {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100} ></input> |};;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "input";
    attributes =
     [Ohtml__.Doc.Bool_attribute "disabled";
      Ohtml__.Doc.Code_attribute "Spring_oml.attribute \"name\" \"value\"";
      Ohtml__.Doc.Name_val_attribute ("attr1", "value1");
      Ohtml__.Doc.Name_val_attribute ("attr2", "val2");
      Ohtml__.Doc.Name_val_attribute ("attr3", "val3");
      Ohtml__.Doc.Name_code_val_attribute ("attr4", " string_of_int 100")];
    children = []}}
```

## HTML Comment

```ocaml
# Ohtml.parse_element "<html><!-- Hello world comment --></html>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "html"; attributes = [];
    children = [Ohtml__.Doc.Html_comment " Hello world comment "]}}

# Ohtml.parse_element "<html><![ Hello world conditional comment ]></html>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "html"; attributes = [];
    children =
     [Ohtml__.Doc.Html_conditional_comment
       " Hello world conditional comment "]}}
```

## HTML CDATA

```ocaml
# Ohtml.parse_element "<html><![CDATA[ This is CDATA ]]></html>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "html"; attributes = [];
    children = [Ohtml__.Doc.Cdata " This is CDATA "]}}
```

## HTML DTD

```ocaml
# Ohtml.parse_element "<!DOCTYPE html><html></html>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = Some "DOCTYPE html";
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "html"; attributes = []; children = []}}

# Ohtml.parse_element "<!doctype html><html></html>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = Some "doctype html";
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "html"; attributes = []; children = []}}
```

## Text element

```ocaml
# Ohtml.parse_element "<div>  <span>\n\t Hello World {{ \"hello world from OCaml!\"}}    </span>     Hello &Again!     </div>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = None; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml__.Doc.Html_text "Hello World ";
          Ohtml__.Doc.Code
           [Ohtml__.Doc.Code_block " \"hello world from OCaml!\""]]};
      Ohtml__.Doc.Html_text "Hello &Again!     "]}}
```

## @param

```ocaml
# Ohtml.parse_doc "fun a:int b:string ->\n<div>Hello <span>world!</span></div>";;
- : Doc.doc =
{Ohtml__.Doc.fun_args = Some "a:int b:string "; dtd = None;
 root =
  Ohtml__.Doc.Element
   {Ohtml__.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml__.Doc.Html_text "Hello ";
      Ohtml__.Doc.Element
       {Ohtml__.Doc.tag_name = "span"; attributes = [];
        children = [Ohtml__.Doc.Html_text "world!"]}]}}
```
