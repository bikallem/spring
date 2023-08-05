# Csrf tests

```ocaml
open Spring

let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)
let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let nonce = Cstruct.of_string "aaaaaaaaaaaa" 

let form_codec = Csrf.form_codec key
let csrf_tok = Base64.(decode_exn ~pad:false "zaQgjF+KK0vSXlYUPhHTlLx/EY+LgpSgy7BxyAdW9n0")

let session = Session.cookie_codec key
let make_form_submission_request (client_req : Request.client Request.t) =
  let client_req =
    let token_name = Csrf.token_name form_codec in 
    let data = Session.Data.(add token_name csrf_tok empty) in
    let data = Session.encode ~nonce data session in
    let cookie_name = Session.cookie_name session in
    Request.add_cookie ~name:cookie_name ~value:data client_req
  in
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw -> Request.write_client_request client_req bw);
  let buf_read = Eio.Buf_read.of_string (Buffer.contents b) in
  Request.parse_server_request ~session client_addr buf_read

let run_with_random_generator f = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  f ()

let pp_response r =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw ->
    Response.write_server_response bw r;
  );
  Eio.traceln "%s" (Buffer.contents b);;
```

## Csrf.enable_protection/token

```ocaml
# let req = Request.make_server_request ~resource:"/" Method.get client_addr (Eio.Buf_read.of_string "");;
val req : Request.server Request.t = <abstr>

# run_with_random_generator @@ fun () -> Csrf.enable_protection req form_codec;;
- : unit = ()

# Csrf.token req form_codec |> Option.is_some;;
- : bool = true
```

## Csrf.protect_request

Return OK response if the CSRF token in form matches the one in session.

```ocaml
let host = Host.decode "www.example.com"
```

```ocaml
# let csrf_form_req =
    Eio_main.run @@ fun _env ->
    let tok : string = Spring__Secret.encrypt_base64 nonce key csrf_tok in
    let token_name = Csrf.token_name form_codec in 
    let body = Body.writable_form_values 
      [(token_name, [tok]);
       ("name2", ["val c"; "val d"; "val e"])
      ]
    in
    Request.make_client_request
        ~resource:"/post_form"
        host
        Method.post
        body
    |>  make_form_submission_request ;;
val csrf_form_req : Request.server Request.t = <abstr>

# let res = Csrf.protect_request form_codec csrf_form_req (fun _ -> Response.text "hello") ;;
val res : Csrf.response = <abstr>

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
    let token_name = Csrf.token_name form_codec in 
    let body = Body.writable_form_values 
      [(token_name, [tok]);
       ("name2", ["val c"; "val d"; "val e"])
      ]
    in
    Request.make_client_request
        ~resource:"/post_form"
        host
        Method.post
        body
    |>  make_form_submission_request ;;
val csrf_form_req : Request.server Request.t = <abstr>

# let res = Csrf.protect_request form_codec csrf_form_req (fun _ -> Response.text "hello") ;;
val res : Csrf.response = <abstr>

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
  let token_name = Csrf.token_name form_codec in
  Multipart.writable_value_part ~form_name:token_name ~value:tok ;;
val p1 : Multipart.writable Multipart.part = <abstr>

# let p2 = Multipart.writable_value_part ~form_name:"file1" ~value:"file is a text file." ;;
val p2 : Multipart.writable Multipart.part = <abstr>

# let csrf_form_req =
    Eio_main.run @@ fun _env ->
    let form_body = Multipart.writable ~boundary:"--A1B2C3" [p1;p2] in
    Request.make_client_request
        ~resource:"/post_form"
        host
        Method.post
        form_body
    |>  make_form_submission_request ;;
val csrf_form_req : Request.server Request.t = <abstr>

# let res = Csrf.protect_request form_codec csrf_form_req (fun _ -> Response.text "hello") ;;
val res : Csrf.response = <abstr>

# pp_response res;;
+HTTP/1.1 200 OK
+Content-Length: 5
+Content-Type: text/plain; charset=uf-8
+
+hello
- : unit = ()
```
