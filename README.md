# Spring 

A Delightful OCaml web programming library.

### Hightlights:

- [x] `ohtml` - a fast, compiled view engine allowing you to mix HTML with OCaml code
- [x] Type safe, radix-tree based url routing engine. Use ppx to specify route path, e.g. `[%r "/store/products/:int"]`
- [x] Form handling/data upload (multipart/formdata protocol - RFC 9110 - for standards compliance and interoperability)
- [ ] Secure HTTP session based on encrypted cookie
- [ ] Secure HTTP session based on SQLite/Postgres/Mysql
- [x] HTTP Cookies (RFC 6265)
- [x] Type-safe HTTP header manipulation
- [x] Fullly compliant (RFC 7230) HTTP chunked transfer protocol (both client and server)
- [ ] HTTP file server - host/serve static web assets such as `.css, .js, .jpg, .png` etc 
- [x] HTTP/1.1 (RFC 9112) compliant server
- [x] Parallel/Multicore capable HTTP/1.1 server
- [x] HTTP/1.1 client
- [ ] HTTPS client - TLS/1.3 based
- [x] Closely aligned with `eio` io library

### Hello world in Spring [^1]
[^1]: See https://github.com/bikallem/spring/tree/main/examples/hello for full sample

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
