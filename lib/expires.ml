type t =
  | Expired
  | Date of Date.t

let expired = Expired

let is_expired = function
  | Expired -> true
  | Date _ -> false

let date = function
  | Expired -> None
  | Date d -> Some d

let decode v =
  match Date.decode v with
  | d -> Date d
  | exception _ -> Expired

let encode = function
  | Date d -> Date.encode d
  | Expired -> "-1"
