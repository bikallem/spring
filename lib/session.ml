module Data = Map.Make (String)

type nonce = Cstruct.t
type data = string
type key = string
type session_data = string Data.t

type codec =
  { cookie_name : string
  ; encode : nonce -> session_data -> data
  ; decode : data -> session_data
  }

let[@inline] err () = failwith "Invalid session data"

let cookie_codec ?(cookie_name = "___SPRING_SESSION___") key =
  { cookie_name
  ; encode =
      (fun nonce session_data ->
        Data.to_seq session_data
        |> Seq.map (fun (key, v) -> Csexp.(List [ Atom key; Atom v ]))
        |> List.of_seq
        |> fun l ->
        Csexp.List l |> Csexp.to_string |> Secret.encrypt_base64 nonce key)
  ; decode =
      (fun data ->
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
        | _ -> err ())
  }

let cookie_name (t : codec) = t.cookie_name
let decode data (t : codec) = t.decode data
let encode ~nonce session_data (t : codec) = t.encode nonce session_data
