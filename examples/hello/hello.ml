open Spring

let view ~title body = Response.ohtml @@ V.layout_v ~title ~body

let say_hello name _req = view ~title:"Hello Page" @@ V.hello_v name

let display_products _req =
  V.products_v [ "apple"; "oranges"; "bananas" ] |> view ~title:"Products Page"

(*
let _csrf_form _req = 
  Csrf.enable_csrf_protection csrf_codec;
  let tok = Csrf.token csrf_codec in
   

let _csrf_protec _req = 
  Csrf.protect_request (fun _req -> Response.text "okay")
  (fun () -> Response.bad_request)
*)

let shutdown server _req =
  Server.shutdown server;
  Response.not_found

let () =
  Printexc.record_backtrace true;
  Eio_main.run @@ fun env ->
  let dirpath = Eio.Path.(env#fs / "./examples/hello/public") in
  let filepath = Eio.Path.(dirpath / "index.html") in
  let server =
    Server.make ~on_error:raise ~secure_random:env#secure_random env#clock
      env#net
  in
  server
  |> Server.serve_dir ~on_error:raise ~dirpath [%r "/public/**"]
  |> Server.serve_file ~on_error:raise ~filepath [%r "/"]
  |> Server.get [%r "/hello/:string"] say_hello
  |> Server.get [%r "/products"] display_products
  |> Server.get [%r "/shutdown"] @@ shutdown server
  |> Server.run_local ~port:8080
