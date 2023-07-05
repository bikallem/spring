module Map = Map.Make (String)

type cookie_value =
  { name_prefix : Cookie_name_prefix.t option
  ; value : string
  }

type t = cookie_value Map.t

let decode v =
  let r = Buf_read.of_string v in
  let rec aux m =
    let name, value = Buf_read.cookie_pair r in
    let name, name_prefix =
      Cookie_name_prefix.cut_prefix ~case_sensitive:true name
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
  let buf = Buffer.create 10 in
  let i = ref 1 in
  Map.iter
    (fun name { name_prefix; value } ->
      if !i > 1 then Buffer.add_char buf ';';
      (match name_prefix with
      | Some prefix ->
        Buffer.add_string buf @@ Cookie_name_prefix.to_string prefix
      | None -> ());
      Buffer.add_string buf name;
      Buffer.add_char buf '=';
      Buffer.add_string buf value;
      i := !i + 1)
    t;
  Buffer.contents buf

let empty = Map.empty

let name_prefix name t =
  Option.bind (Map.find_opt name t) @@ fun { name_prefix; _ } -> name_prefix

let find_opt cookie_name t =
  Option.map (fun { value; _ } -> value) @@ Map.find_opt cookie_name t

let add ?name_prefix ~name ~value t = Map.add name { name_prefix; value } t

let remove ~name t = Map.remove name t
