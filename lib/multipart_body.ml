open Astring

type t = {
  r : Buf_read.t;
  boundary : string;
  dash_boundary : string;
  final_boundary : string;
  mutable last_line : string; (* last line read *)
  mutable linger : string; (* leftover from last read_into. *)
  mutable eof : bool; (* eof <- true when final_boundary is read. *)
}

open Option.Syntax

let make (body : #Body.readable) =
  let body = (body :> Body.readable) in
  let boundary =
    match
      let* ct = Header.(find body#headers content_type) in
      Content_type.find_param ct "boundary"
    with
    | Some v -> v
    | None -> raise @@ Invalid_argument "body: boundary value not found"
  in
  let dash_boundary = "--" ^ boundary in
  let final_boundary = "--" ^ boundary ^ "--" in
  let r = body#buf_read in
  {
    r;
    boundary;
    dash_boundary;
    final_boundary;
    last_line = "";
    linger = "";
    eof = false;
  }

let boundary t = t.boundary

(* Part *)

type part = {
  form_name : string option;
  filename : string option;
  headers : Header.t;
  flow : Eio.Flow.source;
}

let skip_whitespace s =
  String.filter (function ' ' | '\t' -> false | _ -> true) s

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

let read_into t dst =
  let write_data data =
    let data_len = String.length data in
    let n = min (Cstruct.length dst) data_len in
    Cstruct.blit_from_string data 0 dst 0 n;
    t.linger <-
      (if n < data_len then String.with_range ~first:n ~len:(data_len - n) data
      else "");
    n
  in
  if not @@ String.is_empty t.linger then write_data t.linger
  else if t.eof then raise End_of_file
  else
    let ln = read_line t in
    if is_final_boundary t.final_boundary ln then (
      t.eof <- true;
      raise End_of_file)
    else if is_boundary_delimiter t.dash_boundary ln then (
      t.last_line <- ln;
      raise End_of_file)
    else write_data ln

(* part body flow *)
let part_flow (t : t) : Eio.Flow.source =
  object
    inherit Eio.Flow.source
    method read_into = read_into t
  end

(* TODO replace with take_while_bigstring after https://github.com/ocaml-multicore/eio/pull/449 lands *)
let next_part (t : t) =
  let ln = read_line t in
  if not (is_boundary_delimiter t.dash_boundary ln) then
    failwith @@ "mulitpart: expecting a new part; got line \"" ^ ln ^ "\""
  else
    let headers = Header.parse t.r in
    match Header.(find headers content_disposition) with
    | Some d ->
        if String.equal "form-data" (Content_disposition.disposition d) then
          let filename = Content_disposition.find_param d "filename" in
          let form_name = Content_disposition.find_param d "name" in
          let flow = (part_flow t :> Eio.Flow.source) in
          { filename; form_name; headers; flow }
        else
          failwith
            "multipart: \"Content-Disposition\" header doesn't contain \
             \"form-data\" value"
    | None -> failwith "multipart: \"Content-Disposition\" header not found"

let file_name p = p.filename
let form_name p = p.form_name
let headers p = p.headers
let flow p = p.flow
