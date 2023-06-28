type t =
  | Expired
  | Date of Ptime.t

let decode v =
  match Date.decode v with
  | d -> Date d
  | exception _ -> Expired

let encode = function
  | Date d -> Date.encode d
  | Expired -> "-1"

let expired = Expired

let is_expired = function
  | Expired -> true
  | Date _ -> false

let ptime = function
  | Expired -> None
  | Date d -> Some d