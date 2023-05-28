module Data = Map.Make (String)

type nonce = Cstruct.t
type data = string
type key = string
type session_data = string Data.t

class virtual t ~cookie_name =
  object
    method cookie_name : string = cookie_name
    method virtual encode : nonce -> session_data -> data
    method virtual decode : data -> session_data
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
        List.fold_left
          (fun acc -> function
            | Csexp.(List [ Atom key; Atom value ]) -> Data.add key value acc
            | _ -> err ())
          Data.empty key_values
      | _ -> err ()

    method encode nonce session_data =
      Data.to_seq session_data
      |> Seq.map (fun (key, v) -> Csexp.(List [ Atom key; Atom v ]))
      |> List.of_seq
      |> fun l ->
      Csexp.List l |> Csexp.to_string |> Secret.encrypt_base64 nonce key
  end

let cookie_name (t : #t) = t#cookie_name
let decode data (t : #t) = t#decode data
let encode ~nonce session_data (t : #t) = t#encode nonce session_data
