(** File Handler - handles requests for files. *)

let file_last_modified filepath =
  Eio.Path.with_open_in filepath @@ fun p ->
  (Eio.File.stat p).mtime
  |> Ptime.of_float_s
  |> Option.get
  |> Ptime.truncate ~frac_s:0

let serve ~on_error filepath =
  match
    let content = Eio.Path.load filepath in
    let ct =
      Fpath.v @@ snd filepath
      |> Fpath.filename
      |> Magic_mime.lookup
      |> String.cut ~sep:"/"
      |> Option.get
      |> Content_type.make
    in
    let headers =
      Eio.Path.with_open_in filepath @@ fun p ->
      (Eio.File.stat p).mtime
      |> Ptime.of_float_s
      |> Option.get
      |> Header.(add empty last_modified)
    in
    let headers = Header.(add headers expires Expires.expired) in
    let body = Body.writable_content ct content in
    Response.make_server_response ~headers body
  with
  | res -> res
  | exception Eio.Io (Eio.Fs.E (Not_found _), _) -> Response.not_found
  | exception exn -> on_error exn

let file_not_modified_response req last_modified' =
  let headers = Header.(add empty last_modified last_modified') in
  let version = Request.version req in
  let status = Status.not_modified in
  Response.make_server_response ~version ~status ~headers Body.none

let handle_get ~on_error filepath (req : Request.server Request.t) =
  match Header.(find_opt (Request.headers req) if_modified_since) with
  | Some if_modified_since ->
    let last_modified' = file_last_modified filepath in
    if Ptime.is_later last_modified' ~than:if_modified_since then
      serve ~on_error filepath
    else file_not_modified_response req last_modified'
  | None -> serve ~on_error filepath
