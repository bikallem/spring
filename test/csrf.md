# Csrf tests

```ocaml
open Spring

let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)
let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let nonce = Cstruct.of_string "aaaaaaaaaaaa" 

let form_codec = Csrf.form_codec key 
let csrf_tok = Base64.(decode_exn ~pad:false "zaQgjF+KK0vSXlYUPhHTlLx/EY+LgpSgy7BxyAdW9n0")

let session = Session.cookie_codec key

let make_form_submission_request (client_req : Request.Client.t) =
  let client_req =
    let data = Session.Data.(add form_codec#token_name csrf_tok empty) in
    let data = Session.encode ~nonce data session in
    Request.Client.add_cookie ~name:session#cookie_name ~value:data client_req
  in
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw -> Request.Client.write client_req bw);
  let buf_read = Eio.Buf_read.of_string (Buffer.contents b) in
  Request.parse ~session client_addr buf_read

let run_with_random_generator f = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  f ()

let pp_response r =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    Response.write r bw;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

## Csrf.enable_protection/token

```ocaml
# let req = Request.server_request ~resource:"/" Method.get client_addr (Eio.Buf_read.of_string "");;
val req : Request.server_request = <obj>

# run_with_random_generator @@ fun () -> Csrf.enable_protection req form_codec;;
- : unit = ()

# Csrf.token req form_codec |> Option.is_some;;
- : bool = true
```

## Csrf.protect_request

Return OK response if the CSRF token in form matches the one in session.

```ocaml
# let csrf_form_req =
    Eio_main.run @@ fun _env ->
    let tok : string = Spring__Secret.encrypt_base64 nonce key csrf_tok in
    let body = Body.form_values_writer' 
      [(form_codec#token_name, [tok]);
       ("name2", ["val c"; "val d"; "val e"])
      ]
    in
    Request.Client.make
        ~host:"www.example.com"
        ~resource:"www.example.com/post_form"
        Method.post
        body
    |>  make_form_submission_request ;;
val csrf_form_req : Request.server_request = <obj>

# let res = Csrf.protect_request form_codec csrf_form_req (fun _ -> Response.text "hello") ;;
val res : Response.server_response = <obj>

# pp_response res;;
+HTTP/1.1 200 OK
+Content-Length: 5
+Content-Type: text/plain; charset=uf-8
+
+hello
- : unit = ()
```

Return `Bad Request` response if the CSRF tokens dont' match.

```ocaml
# let csrf_form_req =
    Eio_main.run @@ fun _env ->
    let tok : string = Spring__Secret.encrypt_base64 nonce key "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" in
    let body = Body.form_values_writer' 
      [(form_codec#token_name, [tok]);
       ("name2", ["val c"; "val d"; "val e"])
      ]
    in
    Request.Client.make
        ~host:"www.example.com"
        ~resource:"www.example.com/post_form"
        Method.post
        body
    |>  make_form_submission_request ;;
val csrf_form_req : Request.server_request = <obj>

# let res = Csrf.protect_request form_codec csrf_form_req (fun _ -> Response.text "hello") ;;
val res : Response.server_response = <obj>

# pp_response res;;
+HTTP/1.1 400 Bad Request
+Content-Length: 0
+
+
- : unit = ()
```

Mulitpart/formdata form.

```ocaml
# let p1 = 
  let tok = Spring__Secret.encrypt_base64 nonce key csrf_tok in
  Multipart.make_part (Eio.Flow.string_source tok) form_codec#token_name ;;
val p1 : Eio.Flow.source Multipart.part = <abstr>

# let p2 = Multipart.make_part (Eio.Flow.string_source "file is a text file.") "file1";;
val p2 : Eio.Flow.source Multipart.part = <abstr>

# let csrf_form_req =
    Eio_main.run @@ fun _env ->
    let form_body = Multipart.writable "--A1B2C3" [p1;p2] in
    Request.Client.make
        ~host:"www.example.com"
        ~resource:"www.example.com/post_form"
        Method.post
        form_body
    |>  make_form_submission_request ;;
val csrf_form_req : Request.server_request = <obj>

# let res = Csrf.protect_request form_codec csrf_form_req (fun _ -> Response.text "hello") ;;
val res : Response.server_response = <obj>

# pp_response res;;
+HTTP/1.1 200 OK
+Content-Length: 5
+Content-Type: text/plain; charset=uf-8
+
+hello
- : unit = ()
```
