(** File Handler - handles requests for files. *)

let file_last_modified filepath =
  Eio.Path.with_open_in filepath @@ fun p -> (Eio.File.stat p).mtime

let file_last_modified_header_v last_modified =
  Float.trunc last_modified |> Ptime.of_float_s |> Option.get

let file_etag_header_v last_modified =
  Printf.sprintf "%.6f" last_modified
  |> Digest.string
  |> Digest.to_hex
  |> Etag.make

let serve last_modified' etag' filepath =
  let content = Eio.Path.load filepath in
  let ct =
    Fpath.v @@ snd filepath
    |> Fpath.filename
    |> Magic_mime.lookup
    |> String.cut ~sep:"/"
    |> Option.get
    |> Content_type.make
  in
  let headers = Header.(add empty last_modified last_modified') in
  let headers = Header.(add headers etag etag') in
  let headers = Header.(add headers expires Expires.expired) in
  let body = Body.writable_content ct content in
  Response.make_server_response ~headers body

let file_not_modified_response headers req =
  let version = Request.version req in
  let status = Status.not_modified in
  Response.make_server_response ~version ~status ~headers Body.none

let if_none f = function
  | Some _ as x -> x
  | None -> f ()

let handle_get ~on_error filepath (req : Request.server Request.t) =
  let open Option.Syntax in
  try
    let last_modified_v = file_last_modified filepath in
    let last_modified' = file_last_modified_header_v last_modified_v in
    let etag' = file_etag_header_v last_modified_v in
    let headers = Request.headers req in
    match
      ((* +-- https://datatracker.ietf.org/doc/html/rfc7232#section-3.2 --+ *)
       let* if_none_match = Header.(find_opt headers if_none_match) in
       let etag_matched =
         If_none_match.contains_entity_tag
           (fun etag -> Etag.weak_equal etag etag')
           if_none_match
       in
       if etag_matched then
         let headers = Header.(add empty etag etag') in
         Some (file_not_modified_response headers req)
       else None)
      |> if_none @@ fun () ->
         let* if_modified_since' =
           Header.(find_opt headers if_modified_since)
         in
         if Ptime.is_later last_modified' ~than:if_modified_since' then None
         else
           let headers = Header.(add empty last_modified last_modified') in
           Some (file_not_modified_response headers req)
    with
    | Some res -> res
    | None -> serve last_modified' etag' filepath
  with
  | Eio.Io (Eio.Fs.E (Not_found _), _) -> Response.not_found
  | exn -> on_error exn
