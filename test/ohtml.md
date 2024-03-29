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
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = []; children = []}}

# Ohtml.parse_element "<div />";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = []; children = []}}
```

## Element with children.

```ocaml
# Ohtml.parse_element "<div><span><area/></span><span><area /></span><span><area/></span></div>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
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
  {Node.text "hello"}
  <span id="v" disabled>
    {Node.text "world"}
    <span>text</span>
  </span>
  <span><area/></span>
</div>|}
```

```ocaml
# Ohtml.parse_element s;;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Code [Ohtml.Doc.Code_block "Node.text \"hello\""];
      Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span";
        attributes =
         [Ohtml.Doc.Double_quoted_attribute ("id", "v");
          Ohtml.Doc.Bool_attribute "disabled"];
        children =
         [Ohtml.Doc.Code [Ohtml.Doc.Code_block "Node.text \"world\""];
          Ohtml.Doc.Element
           {Ohtml.Doc.tag_name = "span"; attributes = [];
            children = [Ohtml.Doc.Html_text "text"]}]};
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
  {List.iter 
    (fun a ->
      <section>
        Ohtml.text a
      </section>
      <text>This is a text {}, <hell></hello> </text>
    ) 
    names
  }
</div>
|}
```

```ocaml
# Ohtml.parse_element s;;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Code
       [Ohtml.Doc.Code_block "List.iter \n      (fun a ->\n        ";
        Ohtml.Doc.Code_element
         {Ohtml.Doc.tag_name = "section"; attributes = [];
          children =
           [Ohtml.Doc.Code_block "\n          Ohtml.text a\n        "]};
        Ohtml.Doc.Code_block "\n        ";
        Ohtml.Doc.Code_text "This is a text {}, <hell></hello> ";
        Ohtml.Doc.Code_block "\n      ) \n      names\n    "]]}}
```

## Bool attributes

```ocaml
# Ohtml.parse_element "<input disabled attr1 attr2 attr3></input>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
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
# Ohtml.parse_element "<input attr1-get = attrv\n></input>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes = [Ohtml.Doc.Unquoted_attribute ("attr1-get", "attrv")];
    children = []}}
```

## Quoted attribute value

```ocaml
# Ohtml.parse_element {|<input disabled attr1='value1' attr2=   "val2"      attr3    = val3    ><span></span></input>|};;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes =
     [Ohtml.Doc.Bool_attribute "disabled";
      Ohtml.Doc.Single_quoted_attribute ("attr1", "value1");
      Ohtml.Doc.Double_quoted_attribute ("attr2", "val2");
      Ohtml.Doc.Unquoted_attribute ("attr3", "val3")];
    children =
     [Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = []; children = []}]}}
```

## Code attribute value

```ocaml
# Ohtml.parse_element {|<input attr1=  @"value1" attr2 = @{ string_of_int 100 }></input>|};;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
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
# Ohtml.parse_element {|<input disabled {Spring_oml.attribute "name" "value"} attr1='value1' attr2=   "val2"      attr3    = val3    attr4=@{ string_of_int 100} ></input> |};;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "input";
    attributes =
     [Ohtml.Doc.Bool_attribute "disabled";
      Ohtml.Doc.Code_attribute "Spring_oml.attribute \"name\" \"value\"";
      Ohtml.Doc.Single_quoted_attribute ("attr1", "value1");
      Ohtml.Doc.Double_quoted_attribute ("attr2", "val2");
      Ohtml.Doc.Unquoted_attribute ("attr3", "val3");
      Ohtml.Doc.Name_code_val_attribute ("attr4", " string_of_int 100")];
    children = []}}
```

## HTML Comment

```ocaml
# Ohtml.parse_element "<html><!-- Hello world comment --></html>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = [];
    children = [Ohtml.Doc.Html_comment " Hello world comment "]}}

# Ohtml.parse_element "<html><![ Hello world conditional comment ]></html>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
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
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = [];
    children = [Ohtml.Doc.Cdata " This is CDATA "]}}
```

## HTML DTD

```ocaml
# Ohtml.parse_element "<!DOCTYPE html><html></html>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = Some "DOCTYPE html";
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = []; children = []}}

# Ohtml.parse_element "<!doctype html><html></html>";;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = Some "doctype html";
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "html"; attributes = []; children = []}}
```

## Text element

```ocaml
let s = {|
<div>
  <span>
    Hello World 
    { if true then
        <text>true text</text>
      else 
        <text>false text</text>
    }
  </span>
  Hello &Again!     
</div>
|};;
```

```ocaml
# Ohtml.parse_element s;;
- : Doc.doc =
{Ohtml.Doc.opens = []; fun_args = None; doctype = None;
 root =
  Ohtml.Doc.Element
   {Ohtml.Doc.tag_name = "div"; attributes = [];
    children =
     [Ohtml.Doc.Element
       {Ohtml.Doc.tag_name = "span"; attributes = [];
        children =
         [Ohtml.Doc.Html_text "Hello World \n      ";
          Ohtml.Doc.Code
           [Ohtml.Doc.Code_block " if true then\n          ";
            Ohtml.Doc.Code_text "true text";
            Ohtml.Doc.Code_block "\n        else \n          ";
            Ohtml.Doc.Code_text "false text";
            Ohtml.Doc.Code_block "\n      "]]};
      Ohtml.Doc.Html_text "Hello &Again!     \n  "]}}
```

## Parameters/open

```ocaml
let s = {|
open Spring
open Stdlib
fun a:int b:string ->

<div>
  Hello <span>world!</span>
</div>|}
```

```ocaml
# Ohtml.parse_doc_string s;;
- : Doc.doc =
{Ohtml.Doc.opens = ["Spring"; "Stdlib"]; fun_args = Some " a:int b:string ";
 doctype = None;
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
    Ohtml.gen_ocaml ~function_name:fun_name ~write_ln doc);
  In_channel.with_open_text (fun_name ^ ".ml")
    (fun in_ch -> Eio.traceln "%s" @@ In_channel.input_all in_ch)
```

```ocaml
# let doc = Ohtml.parse_doc_string "fun a:int b:string ->\n<div>Hello <span>world!</span></div>";;
val doc : Doc.doc =
  {Ohtml.Doc.opens = []; fun_args = Some " a:int b:string "; doctype = None;
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
+let func1  a:int b:string  (___b___:Buffer.t) : unit =
+Buffer.add_string ___b___ "<div";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "Hello ";
+Buffer.add_string ___b___ "<span";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "world!";
+Buffer.add_string ___b___ "</span>";
+Buffer.add_string ___b___ "</div>";
+()
- : unit = ()
```

```ocaml
let s ={|
open Spring
open Stdlib

fun products ->

<!DOCTYPE html>
<html>
  <!-- This is a comment -->
  <![ This is a conditional comment ]>
  <![CDATA[ This is cdata ]]>
  <body>
    <div id=div1 
        class="abc ccc aaa" 
        disabled 
        { Ohtml.attribute ~name:"hx-swap" ~value:"outerHTML" } 
        get=@{if true then "/products" else "/index"} >
      Hello 
      <span>world!</span>
      <ol>
      { List.iter (fun product ->
                <li>
                    @product
                </li>
        ) products
      }
      </ol>
    </div>
  </body>
</html>
|}
```

```ocaml
# let doc = Ohtml.parse_doc_string s;;
val doc : Doc.doc =
  {Ohtml.Doc.opens = ["Spring"; "Stdlib"]; fun_args = Some " products ";
   doctype = Some "DOCTYPE html";
   root =
    Ohtml.Doc.Element
     {Ohtml.Doc.tag_name = "html"; attributes = [];
      children =
       [Ohtml.Doc.Html_comment " This is a comment ";
        Ohtml.Doc.Html_conditional_comment " This is a conditional comment ";
        Ohtml.Doc.Cdata " This is cdata ";
        Ohtml.Doc.Element
         {Ohtml.Doc.tag_name = "body"; attributes = [];
          children =
           [Ohtml.Doc.Element
             {Ohtml.Doc.tag_name = "div";
              attributes =
               [Ohtml.Doc.Unquoted_attribute ("id", "div1");
                Ohtml.Doc.Double_quoted_attribute ("class", "abc ccc aaa");
                Ohtml.Doc.Bool_attribute "disabled";
                Ohtml.Doc.Code_attribute
                 " Ohtml.attribute ~name:\"hx-swap\" ~value:\"outerHTML\" ";
                Ohtml.Doc.Name_code_val_attribute
                 ("get", "if true then \"/products\" else \"/index\"")];
              children =
               [Ohtml.Doc.Html_text "Hello \n        ";
                Ohtml.Doc.Element
                 {Ohtml.Doc.tag_name = "span"; attributes = [];
                  children = [Ohtml.Doc.Html_text "world!"]};
                Ohtml.Doc.Element
                 {Ohtml.Doc.tag_name = "ol"; attributes = [];
                  children =
                   [Ohtml.Doc.Code
                     [Ohtml.Doc.Code_block
                       " List.iter (fun product ->\n                  ";
                      Ohtml.Doc.Code_element
                       {Ohtml.Doc.tag_name = "li"; attributes = [];
                        children =
                         [Ohtml.Doc.Code_at "product";
                          Ohtml.Doc.Code_block "\n                      "]};
                      Ohtml.Doc.Code_block "\n          ) products\n        "]]}]}]}]}}

# gen doc ;;
+
+open Spring
+open Stdlib
+let func1  products  (___b___:Buffer.t) : unit =
+Buffer.add_string ___b___ "<!DOCTYPE html>";
+Buffer.add_string ___b___ "<html";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "<!--  This is a comment  -->";
+Buffer.add_string ___b___ "<![  This is a conditional comment  ]>";
+Buffer.add_string ___b___ "<![CDATA[  This is cdata  ]]>";
+Buffer.add_string ___b___ "<body";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "<div";
+Buffer.add_string ___b___ " id=div1";
+Buffer.add_string ___b___ " class=\"abc ccc aaa\"";
+Buffer.add_string ___b___ " disabled";
+Buffer.add_char ___b___ ' ';
+Spring.Ohtml.write_attribute ( Ohtml.attribute ~name:"hx-swap" ~value:"outerHTML"  ) ___b___;
+Buffer.add_string ___b___ " get=\"";
+Buffer.add_string ___b___ @@ Spring.Ohtml.escape_html (if true then "/products" else "/index");
+Buffer.add_string ___b___ "\"";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "Hello
+        ";
+Buffer.add_string ___b___ "<span";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "world!";
+Buffer.add_string ___b___ "</span>";
+Buffer.add_string ___b___ "<ol";
+Buffer.add_string ___b___ ">";
+(
+ List.iter (fun product ->
+
+Buffer.add_string ___b___ "<li";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ (Spring.Ohtml.escape_html @@ product);
+
+
+Buffer.add_string ___b___ "</li>";
+
+          ) products
+
+);
+Buffer.add_string ___b___ "</ol>";
+Buffer.add_string ___b___ "</div>";
+Buffer.add_string ___b___ "</body>";
+Buffer.add_string ___b___ "</html>";
+()
- : unit = ()
```

## `fun -> ` is optional in .ohtml file

```ocaml
let s ={|
<span>Hello, world!</span>
|}
```

```ocaml
# let doc = Ohtml.parse_doc_string s;;
val doc : Doc.doc =
  {Ohtml.Doc.opens = []; fun_args = Some ""; doctype = None;
   root =
    Ohtml.Doc.Element
     {Ohtml.Doc.tag_name = "span"; attributes = [];
      children = [Ohtml.Doc.Html_text "Hello, world!"]}}

# gen doc;;
+
+let func1  (___b___:Buffer.t) : unit =
+Buffer.add_string ___b___ "<span";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "Hello, world!";
+Buffer.add_string ___b___ "</span>";
+()
- : unit = ()
```

# Apply_view 
```ocaml
# let doc = Ohtml.parse_element "<html>{{view1 products}} </html>";;
val doc : Doc.doc =
  {Ohtml.Doc.opens = []; fun_args = None; doctype = None;
   root =
    Ohtml.Doc.Element
     {Ohtml.Doc.tag_name = "html"; attributes = [];
      children = [Ohtml.Doc.Apply_view "view1 products"]}}
# gen doc ;;
+
+let func1  (___b___:Buffer.t) : unit =
+Buffer.add_string ___b___ "<html";
+Buffer.add_string ___b___ ">";
+(view1 products) ___b___;
+Buffer.add_string ___b___ "</html>";
+()
- : unit = ()
```

# Code_at 

```ocaml
let s ={|
open Spring
open Stdlib

fun products ->

<!DOCTYPE html>
<html>
  <!-- This is a comment -->
  <![ This is a conditional comment ]>
  <![CDATA[ This is cdata ]]>
  <body>
    <div id=div1 
        class="abc ccc aaa" 
        disabled 
        { Ohtml.attribute ~name:"hx-swap" ~value:"outerHTML" } 
        get=@{if true then "/products" else "/index"} 
		hx-sse=@"connect:/news_update">
      Hello 
      <span>world!</span>
      <ol>
      { List.iter (fun product ->
        <li>
		    @{if product = "apple" then "red apple" else product}
            <span>@product<text> hello</text></span>
            @product</li>
        ) products
      }
      </ol>
    </div>
  </body>
</html>
|}
```

```ocaml
# let doc = Ohtml.parse_doc_string s;;
val doc : Doc.doc =
  {Ohtml.Doc.opens = ["Spring"; "Stdlib"]; fun_args = Some " products ";
   doctype = Some "DOCTYPE html";
   root =
    Ohtml.Doc.Element
     {Ohtml.Doc.tag_name = "html"; attributes = [];
      children =
       [Ohtml.Doc.Html_comment " This is a comment ";
        Ohtml.Doc.Html_conditional_comment " This is a conditional comment ";
        Ohtml.Doc.Cdata " This is cdata ";
        Ohtml.Doc.Element
         {Ohtml.Doc.tag_name = "body"; attributes = [];
          children =
           [Ohtml.Doc.Element
             {Ohtml.Doc.tag_name = "div";
              attributes =
               [Ohtml.Doc.Unquoted_attribute ("id", "div1");
                Ohtml.Doc.Double_quoted_attribute ("class", "abc ccc aaa");
                Ohtml.Doc.Bool_attribute "disabled";
                Ohtml.Doc.Code_attribute
                 " Ohtml.attribute ~name:\"hx-swap\" ~value:\"outerHTML\" ";
                Ohtml.Doc.Name_code_val_attribute
                 ("get", "if true then \"/products\" else \"/index\"");
                Ohtml.Doc.Name_code_val_attribute
                 ("hx-sse", "\"connect:/news_update\"")];
              children =
               [Ohtml.Doc.Html_text "Hello \n        ";
                Ohtml.Doc.Element
                 {Ohtml.Doc.tag_name = "span"; attributes = [];
                  children = [Ohtml.Doc.Html_text "world!"]};
                Ohtml.Doc.Element
                 {Ohtml.Doc.tag_name = "ol"; attributes = [];
                  children =
                   [Ohtml.Doc.Code
                     [Ohtml.Doc.Code_block
                       " List.iter (fun product ->\n          ";
                      Ohtml.Doc.Code_element
                       {Ohtml.Doc.tag_name = "li"; attributes = [];
                        children =
                         [Ohtml.Doc.Code_at
                           "if product = \"apple\" then \"red apple\" else product";
                          Ohtml.Doc.Code_block "\n  \t\t    \n              ";
                          Ohtml.Doc.Code_element
                           {Ohtml.Doc.tag_name = "span"; attributes = [];
                            children =
                             [Ohtml.Doc.Code_at "product";
                              Ohtml.Doc.Code_text " hello";
                              Ohtml.Doc.Code_block ""]};
                          Ohtml.Doc.Code_at "product"]};
                      Ohtml.Doc.Code_block
                       "\n              \n          ) products\n        "]]}]}]}]}}

# gen doc;;
+
+open Spring
+open Stdlib
+let func1  products  (___b___:Buffer.t) : unit =
+Buffer.add_string ___b___ "<!DOCTYPE html>";
+Buffer.add_string ___b___ "<html";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "<!--  This is a comment  -->";
+Buffer.add_string ___b___ "<![  This is a conditional comment  ]>";
+Buffer.add_string ___b___ "<![CDATA[  This is cdata  ]]>";
+Buffer.add_string ___b___ "<body";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "<div";
+Buffer.add_string ___b___ " id=div1";
+Buffer.add_string ___b___ " class=\"abc ccc aaa\"";
+Buffer.add_string ___b___ " disabled";
+Buffer.add_char ___b___ ' ';
+Spring.Ohtml.write_attribute ( Ohtml.attribute ~name:"hx-swap" ~value:"outerHTML"  ) ___b___;
+Buffer.add_string ___b___ " get=\"";
+Buffer.add_string ___b___ @@ Spring.Ohtml.escape_html (if true then "/products" else "/index");
+Buffer.add_string ___b___ "\"";
+Buffer.add_string ___b___ " hx-sse=\"";
+Buffer.add_string ___b___ @@ Spring.Ohtml.escape_html ("connect:/news_update");
+Buffer.add_string ___b___ "\"";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "Hello
+        ";
+Buffer.add_string ___b___ "<span";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "world!";
+Buffer.add_string ___b___ "</span>";
+Buffer.add_string ___b___ "<ol";
+Buffer.add_string ___b___ ">";
+(
+ List.iter (fun product ->
+
+Buffer.add_string ___b___ "<li";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ (Spring.Ohtml.escape_html @@ if product = "apple" then "red apple" else product);
+
+
+
+Buffer.add_string ___b___ "<span";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ (Spring.Ohtml.escape_html @@ product);
+Buffer.add_string ___b___ " hello";
+
+Buffer.add_string ___b___ "</span>";
+Buffer.add_string ___b___ (Spring.Ohtml.escape_html @@ product);
+Buffer.add_string ___b___ "</li>";
+
+
+          ) products
+
+);
+Buffer.add_string ___b___ "</ol>";
+Buffer.add_string ___b___ "</div>";
+Buffer.add_string ___b___ "</body>";
+Buffer.add_string ___b___ "</html>";
+()
- : unit = ()
```

# Code_at not inside { ... }

```ocaml
# let doc = Ohtml.parse_element {|<html><div>@view1</div><div>@{if true then "a" else "b"}</div></html>|};;
val doc : Doc.doc =
  {Ohtml.Doc.opens = []; fun_args = None; doctype = None;
   root =
    Ohtml.Doc.Element
     {Ohtml.Doc.tag_name = "html"; attributes = [];
      children =
       [Ohtml.Doc.Element
         {Ohtml.Doc.tag_name = "div"; attributes = [];
          children = [Ohtml.Doc.Element_code_at "view1"]};
        Ohtml.Doc.Element
         {Ohtml.Doc.tag_name = "div"; attributes = [];
          children =
           [Ohtml.Doc.Element_code_at "if true then \"a\" else \"b\""]}]}}
# gen doc ;;
+
+let func1  (___b___:Buffer.t) : unit =
+Buffer.add_string ___b___ "<html";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ "<div";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ (Spring.Ohtml.escape_html @@ view1);
+Buffer.add_string ___b___ "</div>";
+Buffer.add_string ___b___ "<div";
+Buffer.add_string ___b___ ">";
+Buffer.add_string ___b___ (Spring.Ohtml.escape_html @@ if true then "a" else "b");
+Buffer.add_string ___b___ "</div>";
+Buffer.add_string ___b___ "</html>";
+()
- : unit = ()
```
