type t = (string * string) list

include Cookie_parser

let cookie_pair s =
  let name = token s in
  eq s;
  let value = cookie_value s in
  (name, value)

let rec skip_ws s =
  if s.pos < String.length s.i then
    match String.get s.i s.pos with
    | ' ' | '\t' ->
      accept s 1;
      skip_ws s
    | _ -> ()
  else ()

let decode v =
  if String.length v = 0 then
    raise (Invalid_argument "[Cookie.decode] argument [v] is empty");
  let s = { i = v; pos = 0 } in
  let rec aux cookies =
    if s.pos < String.length s.i then
      match String.get s.i s.pos with
      | ';' ->
        accept s 1;
        skip_ws s;
        let cookie = cookie_pair s in
        aux (cookie :: cookies)
      | _ -> cookies
    else cookies
  in
  try
    let cookie = cookie_pair s in
    aux [ cookie ]
  with Invalid_argument _ ->
    raise (Invalid_argument "[Cookie.decode] argument [v] is invalid")

let encode t = List.map (fun (k, v) -> k ^ "=" ^ v) t |> String.concat ~sep:"; "
let find t cookie_name = List.assoc_opt cookie_name t
