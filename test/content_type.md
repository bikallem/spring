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
