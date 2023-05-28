# Session unit tests

```ocaml
open Spring

let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let nonce = Cstruct.of_string "aaaaaaaaaaaa" 
```

## Session.cookie_session/encode/decode

```ocaml
# let t = Session.cookie_session key ;;
val t : Session.t = <obj>

# let session_data = 
  Session.Data.(
    add "a" "a_val" empty
    |> add "b" "b_val");;
val session_data : string Session.Data.t = <abstr>

# Session.Data.find_opt "a" session_data;;
- : string option = Some "a_val"

# Session.Data.find_opt "b" session_data;;
- : string option = Some "b_val"

# let data = Session.encode ~nonce session_data t;;
val data : string =
  "YWFhYWFhYWFhYWFhYHOdvSHL4fyIGWh0ayUSVBXbIUXq5NdJtENq4iTIX1doh_MkW46wor8-"

# let t1 = Session.decode data t;;
val t1 : Session.session_data = <abstr>

# Session.Data.find_opt "a" t1;;
- : string option = Some "a_val"

# Session.Data.find_opt "b" t1;;
- : string option = Some "b_val"
```
