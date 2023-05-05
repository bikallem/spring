type t = (string * string) list

let decode v =
  let r = Buf_read.of_string v in
  let rec aux () : (string * string) list =
    let name, value = Buf_read.cookie_pair r in
    (name, value)
    ::
    (match Buf_read.peek_char r with
    | Some ';' ->
      Buf_read.char ';' r;
      Buf_read.ows r;
      aux ()
    | Some _ | None -> [])
  in
  aux ()

let encode t = List.map (fun (k, v) -> k ^ "=" ^ v) t |> String.concat ~sep:"; "
let find t cookie_name = List.assoc_opt cookie_name t
let add ~name ~value t = (name, value) :: t
