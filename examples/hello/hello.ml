open Spring

let say_hello _req = V.view ~title:"Hello Page" V.hello_v

let display_products _req =
  V.products_v [ "apple"; "oranges"; "bananas" ]
  |> V.view ~title:"Products Page"

let () =
  Printexc.record_backtrace true;
  Eio_main.run @@ fun env ->
  Server.app_server ~on_error:raise ~secure_random:env#secure_random env#clock
    env#net
  |> Server.get [%r "/"] say_hello
  |> Server.get [%r "/products"] display_products
  |> Server.run_local ~port:8080
