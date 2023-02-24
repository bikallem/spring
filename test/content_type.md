# Content_type tests

```ocaml
open Spring
```

## Content_type.decode 

```ocaml
# let t = Content_type.decode "multipart/form-data; boundary=---------------------------735323031399963166993862150; charset=\"utf-8\"" ;;
val t : Content_type.t = <abstr>

# Content_type.find_param t "boundary" ;;
- : string option =
Some "---------------------------735323031399963166993862150"

# Content_type.find_param t "charset" ;;
- : string option = Some "utf-8"

# let t = Content_type.decode "multipart/form-data; boundary=---------------------------735323031399963166993862150; charset=utf-8" ;;
val t : Content_type.t = <abstr>

# Content_type.find_param t "charset" ;;
- : string option = Some "utf-8"
```

## Content_type.media_type

```ocaml
# Content_type.media_type t ;;
- : Content_type.media_type = ("multipart", "form-data")
```

## Content_type.charset

```ocaml
# Content_type.charset t ;;
- : string option = Some "utf-8"
```

## Content_type.make/Content_type.find_param

```ocaml
# let t = Content_type.make ~params:["charset","\"utf-8\""; "boundary", "------as28383ddd"] ("text", "plain");;
val t : Content_type.t = <abstr>

# Content_type.charset t ;;
- : string option = Some "\"utf-8\""

# Content_type.media_type t;;
- : Content_type.media_type = ("text", "plain")

# Content_type.find_param t "charset";;
- : string option = Some "\"utf-8\""

# Content_type.find_param t "boundary";;
- : string option = Some "------as28383ddd"
```

## Content_type.encode

```ocaml
# Content_type.encode t;;
- : string = "text/plain; boundary=------as28383ddd; charset=\"utf-8\""
```
