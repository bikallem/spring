open Spring

let say_hello _req =
  let v = V.layout_v ~title:"Hello Page" ~body:V.hello_v in
  Response.ohtml v

let display_products _req =
  let body = V.products_v [ "apple"; "oranges"; "bananas" ] in
  let v = V.layout_v ~title:"Products Page" ~body in
  Response.ohtml v

let () =
  Eio_main.run @@ fun env ->
  Server.routed_server ~on_error:raise env#clock env#net
  |> Server.get [%r "/"] say_hello
  |> Server.get [%r "/products"] display_products
  |> Server.run_local ~port:8080
