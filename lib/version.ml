type t = int * int (* major, minor*)

let http1_1 = (1, 1)
let equal (a : t) (b : t) = a = b

let to_string (major, minor) =
  "HTTP/" ^ string_of_int major ^ "." ^ string_of_int minor

let pp fmt t = Format.fprintf fmt "%s" @@ to_string t
