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

# let a : int Method.t = Method.make "get" 1;;
val a : int Method.t = <abstr>

# Method.(equal a get);;
Line 1, characters 17-20:
Error: This expression has type Body.none t
       but an expression was expected of type int t
       Type
         Body.none =
           < write_body : Eio.Buf_write.t -> unit;
             write_header : (name:string -> value:string -> unit) -> unit >
       is not compatible with type int
```
