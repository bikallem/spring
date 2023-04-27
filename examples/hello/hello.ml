open Spring

let hello _req =
  let v = V.layout_v ~title:"Hello Page" ~body:V.hello_v in
  Response.ohtml v

let router : Spring.Server.pipeline =
 fun next req ->
  match Spring.Request.resource req with
  | "/" -> hello req
  | "/products" ->
    let body = V.products_v [ "apple"; "oranges"; "bananas" ] in
    let v = V.layout_v ~title:"Products Page" ~body in
    Response.ohtml v
  | _ -> next req

let () =
  Eio_main.run @@ fun env ->
  let handler : Spring.Server.handler =
    Spring.Server.strict_http env#clock
    @@ router @@ Spring.Server.not_found_handler
  in
  let server = Spring.Server.make ~on_error:raise env#clock env#net handler in
  Spring.Server.run_local ~port:8080 server
