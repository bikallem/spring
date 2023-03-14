# Spring 

A Delightful OCaml web programming library.


Perhaps a continuation of `cohttp-eio` - https://github.com/mirage/ocaml-cohttp/tree/master/cohttp-eio 

# Hello world in Spring

```
open Spring

let router : Server.pipeline =
 fun next req ->
  match Request.resource req with
  | "/" -> Response.text "hello, there"
  | _ -> next req

let () =
  Eio_main.run @@ fun env ->
  let handler : Server.handler = router @@ Server.not_found_handler in
  let server = Server.make ~on_error:raise env#clock env#net handler in
  Server.run_local ~port:8080 server
```
