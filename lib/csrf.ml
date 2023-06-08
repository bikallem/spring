type token = string
type key = string

class virtual t ~token_name ~key =
  object
    method token_name : string = token_name

    method encode_csrf_token : token -> string =
      fun tok ->
        let nonce = Mirage_crypto_rng.generate Secret.nonce_size in
        Secret.encrypt_base64 nonce key tok

    method virtual decode_csrf_token : Request.server_request -> token option
  end

let csrf_protected_form ?(token_name = "__csrf_token__") key =
  object
    inherit t ~token_name ~key

    method decode_csrf_token req =
      let open Option.Syntax in
      let* ct = Header.(find_header_opt content_type req) in
      let* tok =
        match (Content_type.media_type ct :> string * string) with
        | "application", "x-www-form-urlencoded" -> (
          let* toks = Body.read_form_values req |> List.assoc_opt token_name in
          match toks with
          | tok :: _ -> Some tok
          | _ -> None)
        | "multipart", "formdata" ->
          let rdr = Multipart.reader req in
          (* Note: anticsrf field must be the first field in multipart/formdata form. *)
          let anticsrf_part = Multipart.next_part rdr in
          let* anticsrf_field = Multipart.form_name anticsrf_part in
          if String.equal anticsrf_field token_name then
            Multipart.reader_flow anticsrf_part
            |> Buf_read.of_flow ~max_size:Int.max_int
            |> Buf_read.take_all
            |> Option.some
          else None
        | _ -> None
      in
      Secret.decrypt_base64 key tok |> Option.some
  end

let session_token (req : #Request.server_request) (t : #t) =
  Request.find_session_data t#token_name req

let enable_csrf_protection (req : #Request.server_request) (t : #t) =
  match Request.find_session_data t#token_name req with
  | Some _ -> ()
  | None ->
    let tok = Mirage_crypto_rng.generate 32 |> Cstruct.to_string in
    Request.add_session_data ~name:t#token_name ~value:tok req

let decode_csrf_token (req : #Request.server_request) (t : #t) =
  t#decode_csrf_token (req :> Request.server_request)

let encode_csrf_token tok (t : #t) = t#encode_csrf_token tok

exception Csrf_protection_not_enabled

let ohtml_form_field (req : #Request.server_request) (t : #t) (b : Buffer.t) =
  let tok =
    match session_token req t with
    | Some tok -> encode_csrf_token tok t
    | None -> raise Csrf_protection_not_enabled
  in
  let input =
    Printf.sprintf "<input type=\"hidden\" name=\"%s\" value=\"%s\">"
      t#token_name tok
  in
  Buffer.add_string b input

let protect_request
    ?(on_fail = fun () -> Response.bad_request)
    f
    (t : #t)
    (req : #Request.server_request) : Response.server_response =
  let open Option.Syntax in
  match
    let* csrf_session_tok = session_token req t in
    let+ csrf_tok = decode_csrf_token req t in
    (csrf_session_tok, csrf_tok)
  with
  | Some (tok1, tok2) when String.equal tok1 tok2 -> f req
  | _ -> on_fail ()
