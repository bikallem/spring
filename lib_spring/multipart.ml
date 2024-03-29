(* Stream *)

type stream =
  { r : Buf_read.t
  ; boundary : string
  ; dash_boundary : string
  ; final_boundary : string
  ; mutable last_line : string (* last line read *)
  ; mutable linger : string (* leftover from last read_into. *)
  ; mutable eof : bool (* eof <- true when final_boundary is read. *)
  }

open Option.Syntax

let stream body =
  let boundary =
    match
      let* ct = Headers.(find_opt content_type @@ Body.headers body) in
      Content_type.find_param ct "boundary"
    with
    | Some v -> v
    | None -> raise @@ Invalid_argument "body: boundary value not found"
  in
  let dash_boundary = "--" ^ boundary in
  let final_boundary = "--" ^ boundary ^ "--" in
  let r = Body.buf_read body in
  { r
  ; boundary
  ; dash_boundary
  ; final_boundary
  ; last_line = ""
  ; linger = ""
  ; eof = false
  }

let boundary s = s.boundary

(* Part *)

type 'a part =
  { t : 'a
  ; form_name : string
  ; filename : string option
  ; headers : Headers.t
  ; mutable body_eof : bool (* true if body read is complete. *)
  }

let file_name p = p.filename

let form_name p = p.form_name

let headers p = p.headers

let skip_whitespace s =
  String.filter
    (function
      | ' ' | '\t' -> false
      | _ -> true)
    s

let is_final_boundary final_boundary ln =
  if not (String.is_prefix ~affix:final_boundary ln) then false
  else
    let rest = String.with_range ~first:(String.length final_boundary) ln in
    let rest = skip_whitespace rest in
    String.length rest = 0

let is_boundary_delimiter dash_boundary ln =
  if not (String.is_prefix ~affix:dash_boundary ln) then false
  else
    let rest = String.with_range ~first:(String.length dash_boundary) ln in
    let rest = skip_whitespace rest in
    String.length rest = 0

let read_line t =
  if t.eof then raise End_of_file
  else if not (String.is_empty t.last_line) then (
    let ln = t.last_line in
    t.last_line <- "";
    ln)
  else Buf_read.line t.r

let read_into p dst =
  let write_data data =
    let data_len = String.length data in
    let n = min (Cstruct.length dst) data_len in
    Cstruct.blit_from_string data 0 dst 0 n;
    p.t.linger <-
      (if n < data_len then String.with_range ~first:n ~len:(data_len - n) data
       else "");
    n
  in
  if not @@ String.is_empty p.t.linger then write_data p.t.linger
  else if p.t.eof then raise End_of_file
  else if p.body_eof then raise End_of_file
  else
    let ln = read_line p.t in
    if is_final_boundary p.t.final_boundary ln then (
      p.t.eof <- true;
      raise End_of_file)
    else if is_boundary_delimiter p.t.dash_boundary ln then (
      p.body_eof <- true;
      p.t.last_line <- ln;
      raise End_of_file)
    else write_data ln

(* part body flow *)
let as_flow p : Eio.Flow.source =
  object
    inherit Eio.Flow.source

    method read_into = read_into p
  end

let read_all p =
  let buf = Buffer.create 10 in
  let sink = Eio.Flow.buffer_sink buf in
  let source = as_flow p in
  Eio.Flow.copy source sink;
  Buffer.contents buf

let next_part s =
  let ln = read_line s in
  if not (is_boundary_delimiter s.dash_boundary ln) then
    failwith @@ "mulitpart: expecting a new part; got line \"" ^ ln ^ "\""
  else
    let headers = Headers.parse s.r in
    match Headers.(find_opt content_disposition headers) with
    | Some d ->
      if String.equal "form-data" (Content_disposition.disposition d) then
        let filename = Content_disposition.find_param d "filename" in
        let form_name =
          match Content_disposition.find_param d "name" with
          | Some name -> name
          | None -> raise (Failure "'name' attribute missing from part")
        in
        { t = s; filename; form_name; headers; body_eof = false }
      else
        failwith
          "multipart: \"Content-Disposition\" header doesn't contain \
           \"form-data\" value"
    | None -> failwith "multipart: \"Content-Disposition\" header not found"

(* Form *)

module Map = Map.Make (String)

type value_field = string

type file_field = string part

type form =
  { values : value_field Map.t
  ; files : file_field Map.t
  }

let make_file_part part =
  let content = read_all part in
  { t = content
  ; form_name = part.form_name
  ; filename = part.filename
  ; headers = part.headers
  ; body_eof = true
  }

let form body =
  let s = stream body in
  let rec aux t =
    try
      let part = next_part s in
      match file_name part with
      | Some _ ->
        let file_part = make_file_part part in
        aux { t with files = Map.add part.form_name file_part t.files }
      | None ->
        let content = read_all part in
        aux { t with values = Map.add part.form_name content t.values }
    with End_of_file -> t
  in
  aux { values = Map.empty; files = Map.empty }

let file_content p = p.t

let find_value_field name t = Map.find_opt name t.values

let find_file_field name t = Map.find_opt name t.files

(* Writer *)

type writable = Eio.Flow.source

let writable_value_part ~form_name ~value =
  { t = Eio.Flow.string_source value
  ; form_name
  ; filename = None
  ; headers = Headers.empty
  ; body_eof = true
  }

let writable_file_part ?(headers = Headers.empty) ~filename ~form_name body =
  let filename = Some filename in
  { t = (body :> Eio.Flow.source)
  ; form_name
  ; filename
  ; headers
  ; body_eof = false
  }

let write_part bw boundary part =
  let params =
    List.filter_map
      (fun (k, v) -> Option.bind v (fun x -> Some (k, x)))
      [ ("name", Some part.form_name); ("filename", part.filename) ]
  in
  let headers =
    let cd = Content_disposition.make ~params "form-data" in
    Headers.(add content_disposition cd part.headers)
  in
  Eio.Buf_write.string bw "--";
  Eio.Buf_write.string bw boundary;
  Eio.Buf_write.string bw "\r\n";
  Headers.write bw headers;
  Eio.Buf_write.string bw "\r\n";
  Eio.Buf_read.of_flow ~max_size:max_int part.t
  |> Eio.Buf_read.take_all
  |> Eio.Buf_write.string bw

let writable ~boundary parts =
  let buf = Buffer.create 10 in
  let s = Eio.Flow.buffer_sink buf in
  Eio.Buf_write.with_flow s (fun bw ->
      (match parts with
      | [] -> ()
      | part :: parts ->
        write_part bw boundary part;
        List.iter
          (fun part ->
            Eio.Buf_write.string bw "\r\n";
            write_part bw boundary part)
          parts);

      Eio.Buf_write.string bw "\r\n--";
      Eio.Buf_write.string bw boundary;
      Eio.Buf_write.string bw "--");

  let content_type =
    Content_type.make
      ~params:[ ("boundary", boundary) ]
      ("multipart", "formdata")
  in
  Body.writable_content content_type (Buffer.contents buf)
