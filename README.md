# Spring 

A Delightful OCaml web programming library.

### Some hightlights:

- [x] Fast, compiled view engine. You can intermix HTML with OCaml code. The view engine is `ohtml`
- [x] Type safe url routing engine utilizing ppx - `[%r "/home/:int"]`
- [x] Multicore capable HTTP/1.1 server builtin with all the required goodness
- [x] Form handling functionality builtin, impelements RFC 9110 for standards compliance and interoperability
- [ ] Cookie based session support
- [ ] SQL database based session support
- [x] Cookie handling builtin
- [ ] TLS HTTPS server builtin
- [x] Type-safe HTTP header manipulation builtin
- [x] HTTP standards based - RFC 9112
- [x] Closely aligned with `eio`
- [ ] Builtin file serving HTTP server

### Hello world in Spring

```hello_v.ohtml```

```html
<span>Hello world!</span>
```

```layout_v.ohtml```

```html
fun ~title ~body ->

<!DOCTYPE html>
<html>
    <head>
        <title>@title</title>
	</head>
  <body>
    {{ body }}
  </body>
</html>
```

```products_v.ohtml```

```html
open Spring

fun products ->

<div id=div1 
    class="abc ccc aaa" 
    disabled 
    { Ohtml.attribute ~name:"hx-swap" ~value:"outerHTML" }
    get=@{if true then "/products" else "/index"} 
		hx-sse=@"connect:/news_update">
  Hello 
  <span>world!</span>
  <h2>Products for sale</h2>
  <ol>
  { List.iter (fun product ->
      <li>
	@{if product = "apple" then "red apple" else product}
	<span>
	  @product<text>hello</text>
	  @product
	</span>
      </li>
    ) products
  }
  </ol>
</div>
```

```hello.ml```

```ocaml
open Spring

let say_hello _req = V.view ~title:"Hello Page" V.hello_v

let display_products _req =
  V.products_v [ "apple"; "oranges"; "bananas" ]
  |> V.view ~title:"Products Page"

let () =
  Eio_main.run @@ fun env ->
  Server.app_server ~on_error:raise env#clock env#net
  |> Server.get [%r "/"] say_hello
  |> Server.get [%r "/products"] display_products
  |> Server.run_local ~port:8080
```
