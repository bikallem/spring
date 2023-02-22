# Transfer_encoding_hdr tests 

```ocaml
open Spring
```

## Transfer_encoding_hdr.decode

```ocaml
# let t = Transfer_encoding_hdr.decode "gzip, chunked";;
val t : Transfer_encoding_hdr.t = <abstr>

# Transfer_encoding_hdr.(exists t chunked);;
- : bool = true

# Transfer_encoding_hdr.(exists t gzip);;
- : bool = true

# let t1 = Transfer_encoding_hdr.decode "chunked";;
val t1 : Transfer_encoding_hdr.t = <abstr>

# Transfer_encoding_hdr.(exists t1 chunked);;
- : bool = true

# Transfer_encoding_hdr.(exists t1 gzip);;
- : bool = false
```

## Transfer_encoding_hdr.remove

```ocaml
# let t2 = Transfer_encoding_hdr.(remove t gzip) ;;
val t2 : Transfer_encoding_hdr.t = <abstr>

# Transfer_encoding_hdr.(exists t2 gzip)
- : bool = false

# Transfer_encoding_hdr.(exists t2 chunked);;
- : bool = true
```

## Transfer_encoding_hdr.encode

```ocaml
# Transfer_encoding_hdr.encode t;;
- : string = "gzip, chunked"

# Transfer_encoding_hdr.encode t1;;
- : string = "chunked"

# Transfer_encoding_hdr.encode t2;;
- : string = "chunked"
```
