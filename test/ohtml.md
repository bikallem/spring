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
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = []; children = []}}

# Ohtml.parse_element "<div />";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = []; children = []}}
```

## Element with children.

```ocaml
# Ohtml.parse_element "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml.Doc.Element
           {Ohtml.Doc.tag_name = "area"; attributes = []; children = []}]};
      Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml.Doc.Element
           {Ohtml.Doc.tag_name = "area"; attributes = []; children = []}]};
      Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml.Doc.Element
           {Ohtml.Doc.tag_name = "area"; attributes = []; children = []}]}]}}
```

## Element with code children.

```ocaml
let s = {|
<div>
  {{Node.text "hello"}
  <span id="v" disabled>
    {Node.text "world"}
    <span></span>
  </span> 
  } 
  <span><area/></span>
</div>|}
```

```ocaml
# Ohtml.parse_element s;;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Code
       [Ohtml.Doc.Code_block "Node.text \"hello\"";
        Ohtml.Doc.Code_element
         {Ohtml.Doc.tag_name = "span";
          attributes =
           [Ohtml.Doc.Name_val_attribute ("id", "v");
            Ohtml.Doc.Bool_attribute "disabled"];
          children =
           [Ohtml.Doc.Code_block "Node.text \"world\"";
            Ohtml.Doc.Code_element
             {Ohtml.Doc.tag_name = "span"; attributes = []; children = []}]}];
      Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml.Doc.Element
           {Ohtml.Doc.tag_name = "area"; attributes = []; children = []}]}]}}
```

## Code element with HTML mixed inside code-block.

```ocaml
let s ={|
<div>
  {{List.iter (fun a -> }
    <section>
      {Ohtml.text a}
    </section>
    <text>This is a text {}, <hell></hello> </text>
    {) names }
  }
</div>
|}
```

```ocaml
# Ohtml.parse_element s;;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Code
       [Ohtml.Doc.Code_block "List.iter (fun a -> ";
        Ohtml.Doc.Code_element
         {Ohtml.Doc.tag_name = "section"; attributes = [];
          children = [Ohtml.Doc.Code_block "Ohtml.text a"]};
        Ohtml.Doc.Code_text "This is a text {}, <hell></hello> ";
        Ohtml.Doc.Code_block ") names "]]}}
```

## Bool attributes

```ocaml
# Ohtml.parse_element "<input disabled attr1 attr2 attr3></input>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes =
     [Ohtml.Doc.Bool_attribute "disabled"; Ohtml.Doc.Bool_attribute "attr1";
      Ohtml.Doc.Bool_attribute "attr2"; Ohtml.Doc.Bool_attribute "attr3"];
    children = []}}
```

## Unquoted attribute value

```ocaml
# Ohtml.parse_element "<input attr1 = attrv\n></input>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes = [Ohtml.Doc.Name_val_attribute ("attr1", "attrv")];
    children = []}}
```

## Quoted attribute value

```ocaml
# Ohtml.parse_element {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes =
     [Ohtml.Doc.Bool_attribute "disabled";
      Ohtml.Doc.Name_val_attribute ("attr1", "value1");
      Ohtml.Doc.Name_val_attribute ("attr2", "val2");
      Ohtml.Doc.Name_val_attribute ("attr3", "val3")];
    children =
     [Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = []; children = []}]}}
```

## Code attribute value

```ocaml
# Ohtml.parse_element {|<input attr1=  {"value1"} attr2 = { string_of_int 100 }></input>|};;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes =
     [Ohtml.Doc.Name_code_val_attribute ("attr1", "\"value1\"");
      Ohtml.Doc.Name_code_val_attribute ("attr2", " string_of_int 100 ")];
    children = []}}
```

## Code attribute, name/value attribute, attribute code value parsing

Name/Value attributes.

```ocaml
# Ohtml.parse_element {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4={ string_of_int 100} ></input> |};;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes =
     [Ohtml.Doc.Bool_attribute "disabled";
      Ohtml.Doc.Code_attribute "Spring_oml.attribute \"name\" \"value\"";
      Ohtml.Doc.Name_val_attribute ("attr1", "value1");
      Ohtml.Doc.Name_val_attribute ("attr2", "val2");
      Ohtml.Doc.Name_val_attribute ("attr3", "val3");
      Ohtml.Doc.Name_code_val_attribute ("attr4", " string_of_int 100")];
    children = []}}
```

## HTML Comment

```ocaml
# Ohtml.parse_element "<html><!-- Hello world comment --></html>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = [];
    children = [Ohtml.Doc.Html_comment " Hello world comment "]}}

# Ohtml.parse_element "<html><![ Hello world conditional comment ]></html>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = [];
    children =
     [Ohtml.Doc.Html_conditional_comment " Hello world conditional comment "]}}
```

## HTML CDATA

```ocaml
# Ohtml.parse_element "<html><![CDATA[ This is CDATA ]]></html>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = [];
    children = [Ohtml.Doc.Cdata " This is CDATA "]}}
```

## HTML DTD

```ocaml
# Ohtml.parse_element "<!DOCTYPE html><html></html>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = Some "DOCTYPE html";
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = []; children = []}}

# Ohtml.parse_element "<!doctype html><html></html>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = Some "doctype html";
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = []; children = []}}
```

## Text element

```ocaml
# Ohtml.parse_element "<div>  <span>\n\t Hello World {{ \"hello world from OCaml!\"}}    </span>     Hello &Again!     </div>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = None; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml.Doc.Html_text "Hello World ";
          Ohtml.Doc.Code
           [Ohtml.Doc.Code_block " \"hello world from OCaml!\""]]};
      Ohtml.Doc.Html_text "Hello &Again!     "]}}
```

## Parameters

```ocaml
# Ohtml.parse_doc_string "fun a:int b:string ->\n<div>Hello <span>world!</span></div>";;
- : Doc.doc =
{Ohtml.Doc.fun_args = Some "a:int b:string "; dtd = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Html_text "Hello ";
      Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children = [Ohtml.Doc.Html_text "world!"]}]}}
```

# Code generation tests

```ocaml
let gen doc = 
  let fun_name = "func1" in
  Out_channel.with_open_gen [Open_wronly; Open_creat;Open_trunc; Open_text] 0o644 (fun_name ^ ".ml")
    (fun out -> 
    let write_ln s = Out_channel.output_string out ("\n" ^ s) in
    Ohtml.gen_ocaml ~write_ln doc);
  In_channel.with_open_text (fun_name ^ ".ml")
    (fun in_ch -> Eio.traceln "%s" @@ In_channel.input_all in_ch)
```


```ocaml
# let doc = Ohtml.parse_doc_string "fun a:int b:string ->\n<div>Hello <span>world!</span></div>";;
val doc : Doc.doc =
  {Ohtml.Doc.fun_args = Some "a:int b:string "; dtd = None;
   root =
    Ohtml.Doc.Element
     {Ohtml.Doc.tag_name = "div"; attributes = [];
      children =
       [Ohtml.Doc.Html_text "Hello ";
        Ohtml.Doc.Element
         {Ohtml.Doc.tag_name = "span"; attributes = [];
          children = [Ohtml.Doc.Html_text "world!"]}]}}

# gen doc ;;
+
+let v a:int b:string  (b:Buffer.t) : unit =
+Buffer.add_string b "<div";
+Buffer.add_string b ">";
+Buffer.add_string b "Hello ";
+Buffer.add_string b "<span";
+Buffer.add_string b ">";
+Buffer.add_string b "world!";
+Buffer.add_string b "</span>";
+Buffer.add_string b "</div>";
- : unit = ()
```

