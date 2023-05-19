module Map = Map.Make (String)

type t = string Map.t

let empty : t = Map.empty
let of_list l = List.to_seq l |> Map.of_seq
let[@inline] err () = failwith "Invalid session data"

let decode key session_data : t =
  let csexp =
    match Secret.decrypt_base64 key session_data |> Csexp.parse_string with
    | Ok v -> v
    | Error _ -> err ()
  in
  match csexp with
  | Csexp.List key_values ->
    List.fold_left
      (fun acc -> function
        | Csexp.(List [ Atom key; Atom value ]) -> Map.add key value acc
        | _ -> err ())
      Map.empty key_values
  | _ -> err ()

let encode nonce key t =
  Map.to_seq t
  |> Seq.map (fun (key, v) -> Csexp.(List [ Atom key; Atom v ]))
  |> List.of_seq
  |> fun l -> Csexp.List l |> Csexp.to_string |> Secret.encrypt_base64 nonce key

let find_opt name t = Map.find_opt name t
