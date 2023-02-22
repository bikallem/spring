type t = int * int (* major, minor *)

let make ~major ~minor = (major, minor)
let http1_1 = (1, 1)
let http1_0 = (1, 0)
let equal (a : t) (b : t) = a = b

let to_string (major, minor) =
  "HTTP/" ^ string_of_int major ^ "." ^ string_of_int minor

let pp fmt t = Format.fprintf fmt "%s" @@ to_string t

let p =
  let open Buf_read.Syntax in
  let* major =
    Buf_read.string "HTTP/" *> Buf_read.any_char <* Buf_read.char '.'
  in
  let* minor = Buf_read.any_char in
  match (major, minor) with
  | '1', '1' -> Buf_read.return http1_1
  | '1', '0' -> Buf_read.return http1_0
  | _ -> (
      try
        let major = Char.escaped major |> int_of_string in
        let minor = Char.escaped minor |> int_of_string in
        Buf_read.return (make ~major ~minor)
      with Failure _ ->
        failwith (Format.sprintf "Invalid HTTP version: (%c,%c)" major minor))
