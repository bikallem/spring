type t =
  { session_data : Session.session_data option; req : Request.server_request }

let make ?session_data req = { session_data; req }
let session_data ctx = ctx.session_data
let replace_session_data data ctx = { ctx with session_data = Some data }
let request ctx = ctx.req
