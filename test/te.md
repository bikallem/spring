## Te_hdr tests

```ocaml
open Spring
```

### Te_hdr.decode, equal

```ocaml
# let t = Te_hdr.decode "trailers, deflate;q=0.5, gzip";;
val t : Te_hdr.t = <abstr>

# Te_hdr.(exists t trailers);;
- : bool = true

# Te_hdr.(exists t deflate);;
- : bool = true

# Te_hdr.(exists t gzip);;
- : bool = true

# Te_hdr.(get_q t gzip);;
- : string option = None

# Te_hdr.(get_q t deflate);;
- : string option = Some "0.5"
```

### Te_hdr.encode

```ocaml
# Te_hdr.encode t;;
- : string = "trailers, deflate;q=0.5, gzip"
```

### Te_hdr.remove

```ocaml
# let t = Te_hdr.(remove t gzip);; 
val t : Te_hdr.t = <abstr>

# Te_hdr.encode t;;
- : string = "trailers, deflate;q=0.5"
```

### Te_hdr.singleton

```ocaml
# let t = Te_hdr.(singleton trailers);;
val t : Te_hdr.t = <abstr>

# Te_hdr.(exists t trailers);;
- : bool = true
```
