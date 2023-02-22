## Method tests 

```ocaml
open Spring 
```

### Method.equal

```ocaml
# Method.(equal get get) ;;
- : bool = true

# Method.(equal get post) ;;
- : bool = false
```

### Method.make

```ocaml
# let lock = Method.make "lock" ;;
val lock : Method.t = "lock"

# let a = Method.make "get" ;;
val a : Method.t = "get"

# Method.(equal a get);;
- : bool = true
```

## Method.to_string

```ocaml
# let m = Method.(to_string get) ;;
val m : Method.t = "get"

# String.equal "get" (m :> string) ;;
- : bool = true
```
