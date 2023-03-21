open Spring

let products_view products : Ohtml.html_writer =
 fun b ->
  Buffer.add_string b "<html>";
  Buffer.add_string b "<body>";
  Buffer.add_string b "<ul>";
  (Spring.Ohtml.iter
     (fun p b ->
       Buffer.add_string b "<li>";
       Spring.Ohtml.text p b;
       Buffer.add_string b "</li>")
     products)
    b;
  Buffer.add_string b "</ul>";
  Buffer.add_string b "</body>";
  Buffer.add_string b "</html>"

let ohtml : Ohtml.html_writer -> Spring.Response.server_response =
 fun f ->
  let b = Buffer.create 10 in
  f b;
  let content = Buffer.contents b in
  Spring.Response.html content

let hello _req = ohtml @@ V_hello.v [ "apple"; "oranges"; "bananas" ]

let router : Spring.Server.pipeline =
 fun next req ->
  match Spring.Request.resource req with
  | "/" -> hello req
  | "/products" -> ohtml @@ products_view [ "apple"; "orange"; "guava" ]
  | _ -> next req

let () =
  Eio_main.run @@ fun env ->
  let handler : Spring.Server.handler =
    Spring.Server.strict_http env#clock
    @@ router @@ Spring.Server.not_found_handler
  in
  let server = Spring.Server.make ~on_error:raise env#clock env#net handler in
  Spring.Server.run_local ~port:8080 server
