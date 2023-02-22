## Te tests

```ocaml
open Spring
```

### Te.decode, equal

```ocaml
# let t = Te.decode "trailers, deflate;q=0.5, gzip";;
val t : Te.t = <abstr>

# Te.(exists t trailers);;
- : bool = true

# Te.(exists t deflate);;
- : bool = true

# Te.(exists t gzip);;
- : bool = true

# Te.(get_q t gzip);;
- : string option = None

# Te.(get_q t deflate);;
- : string option = Some "0.5"
```

### Te.encode

```ocaml
# Te.encode t;;
- : string = "trailers, deflate;q=0.5, gzip"
```

### Te.remove

```ocaml
# let t = Te.(remove t gzip);; 
val t : Te.t = <abstr>

# Te.encode t;;
- : string = "trailers, deflate;q=0.5"
```

### Te.singleton

```ocaml
# let t = Te.(singleton trailers);;
val t : Te.t = <abstr>

# Te.(exists t trailers);;
- : bool = true
```
