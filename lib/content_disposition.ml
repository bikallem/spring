open Astring

type t =
  { disposition : string
  ; parameters : string String.Map.t
  }

let make ?(params = []) disposition =
  let parameters = String.Map.of_seq @@ List.to_seq params in
  { disposition = String.Ascii.lowercase disposition; parameters }

let decode v =
  let open Buf_read in
  let r = of_string v in
  let disposition = token r in
  let parameters = parameters r |> String.Map.of_list in
  { disposition = String.Ascii.lowercase disposition; parameters }

let encode t =
  let buf = Buffer.create 10 in
  Buffer.add_string buf t.disposition;
  String.Map.iter
    (fun name value ->
      Buffer.add_string buf "; ";
      Buffer.add_string buf name;
      Buffer.add_string buf "=";
      Buffer.add_string buf value)
    t.parameters;
  Buffer.contents buf

let disposition t = t.disposition

let find_param t param =
  let param = String.Ascii.lowercase param in
  String.Map.find_opt param t.parameters
