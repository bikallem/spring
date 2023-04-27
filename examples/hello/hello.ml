open Spring

let ohtml : Ohtml.t -> Spring.Response.server_response =
 fun f ->
  let b = Buffer.create 10 in
  f b;
  let content = Buffer.contents b in
  Spring.Response.html content

let hello _req =
  let v = V.layout_v "Hello Page" V.hello_v in
  ohtml v

let router : Spring.Server.pipeline =
 fun next req ->
  match Spring.Request.resource req with
  | "/" -> hello req
  | "/products" ->
    let v =
      V.layout_v "Products Page"
      @@ V.products_v [ "apple"; "oranges"; "bananas" ]
    in
    ohtml v
  | _ -> next req

let () =
  Eio_main.run @@ fun env ->
  let handler : Spring.Server.handler =
    Spring.Server.strict_http env#clock
    @@ router @@ Spring.Server.not_found_handler
  in
  let server = Spring.Server.make ~on_error:raise env#clock env#net handler in
  Spring.Server.run_local ~port:8080 server
