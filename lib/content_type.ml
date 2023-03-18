type t = { type_ : string; sub_type : string; parameters : string String.Map.t }
type media_type = string * string

open Buf_read.Syntax
open Buf_read

let p r =
  let type_ = token r |> String.Ascii.lowercase in
  let sub_type = (char '/' *> token) r |> String.Ascii.lowercase in
  let parameters = parameters r in
  let parameters = String.Map.of_list parameters in
  { type_; sub_type; parameters }

let make ?(params = []) (type_, sub_type) =
  let parameters =
    List.map (fun (k, v) -> (String.Ascii.lowercase k, v)) params
    |> String.Map.of_list
  in
  let type_ = String.Ascii.lowercase type_ in
  let sub_type = String.Ascii.lowercase sub_type in
  { type_; sub_type; parameters }

let decode v = p (of_string v)

let encode t =
  let buf = Buffer.create 10 in
  Buffer.add_string buf t.type_;
  Buffer.add_string buf "/";
  Buffer.add_string buf t.sub_type;
  String.Map.iter
    (fun name value ->
      Buffer.add_string buf "; ";
      Buffer.add_string buf name;
      Buffer.add_string buf "=";
      Buffer.add_string buf value)
    t.parameters;
  Buffer.contents buf

let media_type t = (t.type_, t.sub_type)

let find_param t name =
  String.Map.find_opt (String.Ascii.lowercase name) t.parameters

let charset t = String.Map.find_opt "charset" t.parameters
