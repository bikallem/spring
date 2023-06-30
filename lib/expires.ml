type t =
  | Expired of string
  | Date of Date.t

let of_date d = Date d

let expired = Expired "0"

let is_expired = function
  | Expired _ -> true
  | Date _ -> false

let date = function
  | Expired _ -> None
  | Date d -> Some d

let decode v =
  match Date.decode v with
  | d -> Date d
  | exception _ -> Expired v

let encode = function
  | Date d -> Date.encode d
  | Expired v -> v

let pp fmt t = Format.fprintf fmt "%s" @@ encode t
