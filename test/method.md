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
# let lock : Body.none Method.t = Method.make "lock" Body.none ;;
val lock : Body.none Method.t = <abstr>

# let a : Body.writer Method.t = Method.make "get" Body.none ;;
val a : Body.writer Method.t = <abstr>

# Method.(equal a get);;
- : bool = true
```
