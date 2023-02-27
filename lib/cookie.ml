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
  let cookie = cookie_pair s in
  aux [ cookie ]

