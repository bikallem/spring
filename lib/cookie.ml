module Map = Map.Make (String)

type t = string Map.t

let decode v =
  let r = Buf_read.of_string v in
  let rec aux m =
    let name, value = Buf_read.cookie_pair r in
    let m = Map.add name value m in
    match Buf_read.peek_char r with
    | Some ';' ->
      Buf_read.char ';' r;
      Buf_read.ows r;
      aux m
    | Some _ | None -> m
  in
  aux Map.empty

let encode t =
  Map.to_seq t |> List.of_seq
  |> List.map (fun (k, v) -> k ^ "=" ^ v)
  |> String.concat ~sep:"; "

let find t cookie_name = Map.find_opt cookie_name t
let add ~name ~value t = Map.add name value t
let remove ~name t = Map.remove name t
