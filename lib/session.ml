module Map = Map.Make (String)

type nonce = Cstruct.t
type data = string
type key = string

class virtual t ~cookie_name =
  object (_ : 'a)
    val session_data : string Map.t = Map.empty
    method cookie_name : string = cookie_name
    method session_data = session_data

    method add ~name ~value =
      let session_data = Map.add name value session_data in
      {<session_data>}

    method virtual encode : nonce -> data
    method virtual decode : data -> 'a
  end

let[@inline] err () = failwith "Invalid session data"

let cookie_session ?(cookie_name = "___SPRING_SESSION___") key =
  object (_ : 'a)
    inherit t ~cookie_name

    method decode data =
      let csexp =
        match Secret.decrypt_base64 key data |> Csexp.parse_string with
        | Ok v -> v
        | Error _ -> err ()
      in
      match csexp with
      | Csexp.List key_values ->
        let session_data =
          List.fold_left
            (fun acc -> function
              | Csexp.(List [ Atom key; Atom value ]) -> Map.add key value acc
              | _ -> err ())
            Map.empty key_values
        in
        {<session_data>}
      | _ -> err ()

    method encode nonce =
      Map.to_seq session_data
      |> Seq.map (fun (key, v) -> Csexp.(List [ Atom key; Atom v ]))
      |> List.of_seq
      |> fun l ->
      Csexp.List l |> Csexp.to_string |> Secret.encrypt_base64 nonce key
  end

let cookie_name (t : #t) = t#cookie_name
let decode data (t : #t) = t#decode data
let encode ~nonce (t : #t) = t#encode nonce
let find_opt name (t : #t) = Map.find_opt name t#session_data
let add ~name ~value (t : #t) = t#add ~name ~value
