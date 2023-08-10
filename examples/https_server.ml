open Spring

let server_certificates env =
  let ( / ) = Eio.Path.( / ) in
  let dir = env#cwd in
  let certificate =
    X509_eio.private_of_pems ~cert:(dir / "server.pem")
      ~priv_key:(dir / "server.key")
  in
  let ec_certificate =
    X509_eio.private_of_pems ~cert:(dir / "server-ec.pem")
      ~priv_key:(dir / "server-ec.key")
  in
  [ certificate; ec_certificate ]

let say_hello _req = Response.text "Hello, world!"

let () =
  Eio_main.run @@ fun env ->
  let tls_certificates = server_certificates env in
  let server =
    Server.make ~on_error:raise ~secure_random:env#secure_random
      ~make_handler:(fun _ -> say_hello)
      env#clock env#net
  in
  Eio.Fiber.both
    (fun () ->
      Eio.traceln "server -> start";
      Server.run_local ~tls_certificates ~port:8080 server;
      Eio.traceln "server done.")
    (fun () ->
      Eio.traceln "client -> start";
      Eio.Switch.run @@ fun sw ->
      let client = Client.make ~authenticate_tls:false sw env#net in
      Client.get client "https://localhost:8080/hello" (fun res ->
          Response.readable res
          |> Body.read_content
          |> Option.get
          |> Eio.traceln "client <- %s");
      Eio.traceln "client done.";
      Server.shutdown server)
