# Transfer_encoding tests 

```ocaml
open Spring
```

## Transfer_encoding.decode

```ocaml
# let t = Transfer_encoding.decode "gzip, chunked";;
val t : Transfer_encoding.t = <abstr>

# Transfer_encoding.(exists t chunked);;
- : bool = true

# Transfer_encoding.(exists t gzip);;
- : bool = true

# let t1 = Transfer_encoding.decode "chunked";;
val t1 : Transfer_encoding.t = <abstr>

# Transfer_encoding.(exists t1 chunked);;
- : bool = true

# Transfer_encoding.(exists t1 gzip);;
- : bool = false
```

## Transfer_encoding.remove

```ocaml
# let t2 = Transfer_encoding.(remove t gzip) ;;
val t2 : Transfer_encoding.t = <abstr>

# Transfer_encoding.(exists t2 gzip)
- : bool = false

# Transfer_encoding.(exists t2 chunked);;
- : bool = true
```

## Transfer_encoding.encode

```ocaml
# Transfer_encoding.encode t;;
- : string = "gzip, chunked"

# Transfer_encoding.encode t1;;
- : string = "chunked"

# Transfer_encoding.encode t2;;
- : string = "chunked"
```

## Transfer_encoding.singleon

```ocaml
# let t = Transfer_encoding.(singleton chunked);;
val t : Transfer_encoding.t = <abstr>

# Transfer_encoding.(exists t chunked) ;;
- : bool = true
```
