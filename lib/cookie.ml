module Map = Map.Make (String)

type cookie_value =
  { name_prefix : string option
  ; value : string
  }

type t = cookie_value Map.t

let decode v =
  let r = Buf_read.of_string v in
  let rec aux m =
    let (name, name_prefix), value =
      Buf_read.cookie_pair ~name_prefix_case_sensitive:true r
    in
    let m = Map.add name { name_prefix; value } m in
    match Buf_read.peek_char r with
    | Some ';' ->
      Buf_read.char ';' r;
      Buf_read.ows r;
      aux m
    | Some _ | None -> m
  in
  aux Map.empty

let encode t =
  Map.to_seq t
  |> List.of_seq
  |> List.map (fun (k, { name_prefix; value }) ->
         let name =
           match name_prefix with
           | Some prefix -> prefix ^ k
           | None -> k
         in
         name ^ "=" ^ value)
  |> String.concat ~sep:"; "

let empty = Map.empty

let name_prefix name t =
  Option.bind (Map.find_opt name t) @@ fun { name_prefix; _ } -> name_prefix

let find_opt cookie_name t =
  Option.map (fun { value; _ } -> value) @@ Map.find_opt cookie_name t

let add ?name_prefix ~name ~value t = Map.add name { name_prefix; value } t

let remove ~name t = Map.remove name t
