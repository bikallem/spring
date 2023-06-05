type csrf_token = string

type t =
  { mutable session_data : Session.session_data option
  ; mutable csrf_token : csrf_token option
  ; req : Request.server_request
  }

let make ?session_data req = { session_data; csrf_token = None; req }
let request ctx = ctx.req

(* Session *)
let session_data ctx = ctx.session_data
let reset_session t = t.session_data <- None
let replace_session_data data ctx = ctx.session_data <- Some data

(* Anti-csrf *)
let csrf_token_length = 32

let init_csrf_token t =
  let tok =
    Mirage_crypto_rng.generate csrf_token_length
    |> Cstruct.to_string
    |> Base64.(encode_string ~pad:false ~alphabet:uri_safe_alphabet)
  in
  t.csrf_token <- Some tok

let csrf_token t = t.csrf_token
