open Spring

let view ~title body = Response.ohtml @@ V.layout_v ~title ~body

let say_hello _req = view ~title:"Hello Page" V.hello_v

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

let () =
  Printexc.record_backtrace true;
  Eio_main.run @@ fun env ->
  let serve_dir =
    let dir_path = Eio.Path.(env#fs / "./examples/hello/public") in
    Server.serve_dir ~on_error:raise ~dir_path
  in
  Server.make_app_server ~on_error:raise ~secure_random:env#secure_random
    env#clock env#net
  |> Server.get [%r "/public/**"] serve_dir
  |> Server.get [%r "/"] @@ serve_dir "index.html"
  |> Server.get [%r "/hello"] say_hello
  |> Server.get [%r "/products"] display_products
  |> Server.run_local ~port:8080
