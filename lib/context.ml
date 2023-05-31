type anticsrf_token = string

type t =
  { mutable session_data : Session.session_data option
  ; mutable anticsrf_token : anticsrf_token option
  ; req : Request.server_request
  }

let make ?session_data ?anticsrf_token req =
  { session_data; anticsrf_token; req }

let request ctx = ctx.req

(* Session *)
let session_data ctx = ctx.session_data
let new_session t = make t.req
let replace_session_data data ctx = ctx.session_data <- Some data

(* Anti-csrf *)
let replace_anticsrf_token tok t = t.anticsrf_token <- Some tok
let anticsrf_token t = t.anticsrf_token
