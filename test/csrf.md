# Csrf tests

```ocaml
open Spring

let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8081)
let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let t = Csrf.form_codec key 

let make_form_submission_request ?(meth=Method.post) ?(resource="/") ?(headers=Header.empty) (w: #Body.writable) =
  Eio_main.run @@ fun env ->
  let b = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink b in
  Eio.Buf_write.with_flow s (fun bw -> w#write_body bw);
  let buf_read = Eio.Buf_read.of_string (Buffer.contents b) in
  let len = String.length @@ Buffer.contents b in
  let headers = Header.(add headers content_length len) in
  Request.server_request ~headers ~resource meth client_addr buf_read

let add_content_type_header headers (typ, subtyp) =
  let ct = Content_type.make (typ, subtyp) in 
  Header.(add headers content_type ct)

let run_with_random_generator f = 
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  f ()
```

## Csrf.enable_protection/token

```ocaml
# let form_req = Request.server_request ~resource:"/form" Method.get client_addr (Eio.Buf_read.of_string "");; 
val form_req : Request.server_request = <obj>

# run_with_random_generator @@ fun () -> Csrf.enable_protection form_req t;;
- : unit = ()

# Csrf.token form_req t |> Option.is_some;;
- : bool = true
```

## Csrf.encode_token/protect_request
```ocaml
# let csrf_form_req = 
  run_with_random_generator @@ fun () ->
  let csrf_tok = Csrf.token form_req t |> Option.get in
  let csrf_tok = Csrf.encode_token csrf_tok t in
  let form_body = 
    Body.form_values_writer 
      [(t#token_name, [csrf_tok]); ("name2", ["val c"; "val d"; "val e"])]
  in
  let headers1 = add_content_type_header Header.empty ("application", "x-www-form-urlencoded") in
  make_form_submission_request ~headers:headers1 form_body;;
val csrf_form_req : Request.server_request = <obj>
```
