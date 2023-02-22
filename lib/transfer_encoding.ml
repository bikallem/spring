type encoding = [ `compress | `deflate | `gzip | `chunked ]

module M = Set.Make (struct
  type t = encoding

  (** `chunked at the last *)
  let compare (a : encoding) (b : encoding) =
    match (a, b) with
    | `chunked, `chunked -> 0
    | `chunked, _ -> 1
    | _, `chunked -> -1
    | `compress, `compress -> 0
    | `compress, _ -> 1
    | _, `compress -> -1
    | `deflate, `deflate -> 0
    | `deflate, _ -> 1
    | _, `deflate -> -1
    | `gzip, `gzip -> 0
end)

type t = M.t

let empty = M.empty
let is_empty = M.is_empty
let exists = M.mem
let add = M.add
let remove = M.remove
let iter = M.iter

let encode t =
  M.to_seq t
  |> List.of_seq
  |> List.map (function
       | `chunked -> "chunked"
       | `compress -> "compress"
       | `deflate -> "deflate"
       | `gzip -> "gzip")
  |> String.concat ", "

let decode v =
  String.split_on_char ',' v
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
  |> List.fold_left
       (fun t te ->
         match te with
         | "chunked" -> M.add `chunked t
         | "compress" -> M.add `compress t
         | "deflate" -> M.add `deflate t
         | "gzip" -> M.add `gzip t
         | v -> failwith @@ "Invalid 'Transfer-Encoding' value " ^ v)
       empty
