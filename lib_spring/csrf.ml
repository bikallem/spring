type token = string

type key = string

type request = Request.server Request.t

type response = Response.server Response.t

type codec =
  { token_name : string
  ; encode : token -> string
  ; decode : request -> token option
  }

let form_codec ?(token_name = "__csrf_token__") key =
  let encode tok =
    let nonce = Mirage_crypto_rng.generate Secret.nonce_size in
    Secret.encrypt_base64 nonce key tok
  in
  let decode (req : request) =
    let open Option.Syntax in
    let headers = Request.headers req in
    let* ct = Headers.(find_opt content_type headers) in
    let* tok =
      match (Content_type.media_type ct :> string * string) with
      | "application", "x-www-form-urlencoded" ->
        Request.readable req
        |> Body.read_form_values
        |> List.assoc_opt token_name
      | "multipart", "formdata" ->
        let rdr = Request.readable req |> Multipart.stream in
        (* Note: anticsrf field must be the first field in multipart/formdata form. *)
        let anticsrf_part = Multipart.next_part rdr in
        let anticsrf_field = Multipart.form_name anticsrf_part in
        if String.equal anticsrf_field token_name then
          Some (Multipart.read_all anticsrf_part)
        else None
      | _ -> None
    in
    Secret.decrypt_base64 key tok |> Option.some
  in
  { token_name; encode; decode }

let token_name (c : codec) = c.token_name

let token (req : request) (c : codec) =
  Request.find_session_data c.token_name req

let enable_protection (req : request) (c : codec) =
  match Request.find_session_data c.token_name req with
  | Some _ -> ()
  | None ->
    let tok = Mirage_crypto_rng.generate 32 |> Cstruct.to_string in
    Request.add_session_data ~name:c.token_name ~value:tok req

let encode_token tok (c : codec) = c.encode tok

exception Csrf_protection_not_enabled

let form_field (req : request) (c : codec) (b : Buffer.t) =
  let tok =
    match token req c with
    | Some tok -> encode_token tok c
    | None -> raise Csrf_protection_not_enabled
  in
  let input =
    Printf.sprintf "<input type=\"hidden\" name=\"%s\" value=\"%s\">"
      c.token_name tok
  in
  Buffer.add_string b input

let protect_request
    ?(on_fail = fun () -> Response.bad_request)
    (c : codec)
    (req : request)
    f =
  let open Option.Syntax in
  match
    let* csrf_session_tok = token req c in
    let+ csrf_tok = c.decode req in
    (csrf_session_tok, csrf_tok)
  with
  | Some (tok1, tok2) when String.equal tok1 tok2 -> f req
  | _ -> on_fail ()
