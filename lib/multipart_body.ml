type t = { body : Body.readable; boundary : string }
type part = { form_name : string; filename : string; headers : Header.t }

let make (body : #Body.readable) =
  let body = (body :> Body.readable) in
  let boundary =
    match Header.(find body#headers content_type) with
    | Some _v -> ""
    | None -> raise @@ Invalid_argument "body: boundary value not found"
  in
  { body; boundary }

let boundary t = t.boundary

let next_part (t : t) =
  let _ = Buf_read.take_all t.body#buf_read in
  failwith "not implemented"

let file_name p = p.filename
let form_name p = p.form_name
let headers p = p.headers
