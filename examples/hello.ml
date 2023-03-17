open Spring
open Ohtml

let products_view products : Node.html_writer =
 fun b ->
  Buffer.add_string b "<html>";
  Buffer.add_string b "<body>";
  Buffer.add_string b "<div>";
  (fun b ->
    List.iter
      (fun p ->
        Buffer.add_string b "<section>";
        (fun b -> Node.html_text p b) b;
        Buffer.add_string b "</section>")
      products)
    b;
  Buffer.add_string b "</div>";
  Buffer.add_string b "</body>";
  Buffer.add_string b "</html>"

let hello_view name : Node.html_writer =
 fun b ->
  Buffer.add_string b "<html>";
  Buffer.add_string b "<body>";
  Buffer.add_string b "<div>";

  (fun b -> Node.html_text name b) b;

  Buffer.add_string b "</div>";
  Buffer.add_string b "</body>";
  Buffer.add_string b "</html>"

let ohtml : Node.html_writer -> Response.server_response =
 fun f ->
  let b = Buffer.create 10 in
  f b;
  let content = Buffer.contents b in
  Response.html content

let hello _req = ohtml @@ hello_view "Bikal"

let router : Server.pipeline =
 fun next req ->
  match Request.resource req with
  | "/" -> hello req
  | "/products" -> ohtml @@ products_view [ "apple"; "orange"; "guava" ]
  | _ -> next req

let () =
  Eio_main.run @@ fun env ->
  let handler : Server.handler =
    Server.strict_http env#clock @@ router @@ Server.not_found_handler
  in
  let server = Server.make ~on_error:raise env#clock env#net handler in
  Server.run_local ~port:8080 server
