# Session unit tests

```ocaml
open Spring

let key = Base64.(decode_exn ~pad:false "knFR+ybPVw/DJoOn+e6vpNNU2Ip2Z3fj1sXMgEyWYhA")
let nonce = Cstruct.of_string "aaaaaaaaaaaa" 
```

## Session.cookie_session

```ocaml
# let t = Session.cookie_session key ;;
val t : Session.t = <obj>

# let t = Session.add ~name:"a" ~value:"a_val" t;;
val t : Session.t = <obj>

# let t = Session.add ~name:"b" ~value:"b_val" t;;
val t : Session.t = <obj>

# Session.find_opt "a" t;;
- : string option = Some "a_val"

# Session.find_opt "b" t;;
- : string option = Some "b_val"

# let data = Session.encode ~nonce t;;
val data : string =
  "YWFhYWFhYWFhYWFhYHOdvSHL4fyIGWh0ayUSVBXbIUXq5NdJtENq4iTIX1doh_MkW46wor8-"

# let t1 = Session.decode data t;;
val t1 : Session.t = <obj>

# Session.find_opt "a" t1;;
- : string option = Some "a_val"

# Session.find_opt "b" t1;;
- : string option = Some "b_val"
```

## Session.decode

```ocaml
# let t2 = Session.decode 
val t2 : string -> (#Session.t as 'a) -> 'a = <fun>
```
