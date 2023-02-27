type t = (string * string) list

include Cookie_parser

let cookie_pair s =
  let name = token s in
  eq s;
  let value = cookie_value s in
  (name, value)

let decode v =
  let s = { i = v; pos = 0 } in
  let rec aux () =
    if s.pos < String.length s.i then
      match String.get s.i s.pos with
      | ';' ->
        accept s 1;
        cookie_pair s :: aux ()
      | _ -> []
    else []
  in
  aux ()
