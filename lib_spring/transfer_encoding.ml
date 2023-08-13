type encoding = string

module M = Set.Make (struct
  type t = encoding

  (** `chunked at the last *)
  let compare (a : encoding) (b : encoding) =
    match (a, b) with
    | "chunked", "chunked" -> 0
    | "chunked", _ -> 1
    | _, "chunked" -> -1
    | _ -> String.compare a b
end)

type t = M.t

let encoding s = s

let compress = "compress"

let deflate = "deflate"

let gzip = "gzip"

let chunked = "chunked"

let singleton enc = M.singleton enc

let is_empty = M.is_empty

let exists t d = M.mem d t

let add t d = M.add d t

let remove t d = M.remove d t

let iter = M.iter

let encode t = M.to_seq t |> List.of_seq |> String.concat ~sep:", "

let decode v =
  String.cuts ~sep:"," v
  |> List.map String.trim
  |> List.filter (fun s -> s <> "")
  |> List.fold_left (fun t te -> M.add te t) M.empty
