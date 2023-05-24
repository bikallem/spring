module Map = Map.Make (String)

type nonce = Cstruct.t
type data = string
type key = string

class virtual t key =
  object (_ : 'a)
    val session_data : string Map.t = Map.empty
    val key : string = key

    method add ~name ~value =
      let session_data = Map.add name value session_data in
      {<session_data>}

    method find_opt name = Map.find_opt name session_data
    method virtual encode : nonce -> data
  end

let[@inline] err () = failwith "Invalid session data"

let cookie_session ?data key =
  let decode data =
    let csexp =
      match Secret.decrypt_base64 key data |> Csexp.parse_string with
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
  in
  object (_ : 'a)
    inherit t key

    val! session_data =
      match data with
      | Some d -> decode d
      | None -> Map.empty

    method encode nonce =
      Map.to_seq session_data
      |> Seq.map (fun (key, v) -> Csexp.(List [ Atom key; Atom v ]))
      |> List.of_seq
      |> fun l ->
      Csexp.List l |> Csexp.to_string |> Secret.encrypt_base64 nonce key
  end

let encode ~nonce (t : #t) = t#encode nonce
let find_opt name (t : #t) = t#find_opt name
let add ~name ~value (t : #t) = t#add ~name ~value
