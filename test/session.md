# Session unit tests

```ocaml
open Spring

let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let nonce = Cstruct.of_string "aaaaaaaaaaaa" 
```

## Session.encode

```ocaml
# let t = Session.of_list ["a", "a_val"; "b", "b_val"];;
val t : Session.t = <abstr>

# let session_data = Session.encode ~nonce ~key t;;
val session_data : string =
  "YWFhYWFhYWFhYWFhYHOdvSHL4fyIGWh0ayUSVBXbIUXq5NdJtENq4iTIX1doh_MkW46wor8-"
```

## Session.decode

```ocaml
# let t' = Session.decode ~key session_data;;
val t' : Session.t = <abstr>

# Session.find_opt "a" t';;
- : string option = Some "a_val"

# Session.find_opt "b" t';;
- : string option = Some "b_val"
```

## Session.add 

```ocaml
# let t = Session.add ~name:"c" ~value:"c_val" t;;
val t : Session.t = <abstr>

# Session.find_opt "c" t;;
- : string option = Some "c_val"
```
