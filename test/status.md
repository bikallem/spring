## Status tests

```ocaml
# open Spring
```

### Status.make 

```ocaml
# let s = Status.make (-1) "asdf";;
Exception: Failure "code: -1 is negative".

# let s = Status.make 0 "asdasdf";;
Exception: Failure "code: 0 is not a three-digit number".

# let s = Status.make 1000 "dddd";;
Exception: Failure "code: 1000 is not a three-digit number".

# let s = Status.make 499 "Client Closed Request";;
val s : Status.t = (499, "Client Closed Request")
```

### Status.equal

```ocaml
# Status.(equal ok ok);;
- : bool = true

# Status.(equal ok created) ;;
- : bool = false
```

### Status.pp

```ocaml
# Status.(to_string ok);;
- : string = "200 OK"
```
