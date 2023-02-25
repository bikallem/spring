# Content_disposition tests

```ocaml
open Spring
```

## Content_disposition.decode

```ocaml
# let t = Content_disposition.decode "form-data; name=\"name\"; filename=\"New document 1.2020_08_01_13_16_42.0.svg\"" ;;
val t : Content_disposition.t = <abstr>

# Content_disposition.disposition t ;;
- : string = "form-data"

# Content_disposition.find_param t "filename" ;;
- : string option = Some "New document 1.2020_08_01_13_16_42.0.svg"

# Content_disposition.find_param t "FILENAME" ;;
- : string option = Some "New document 1.2020_08_01_13_16_42.0.svg"

# Content_disposition.find_param t "name" ;;
- : string option = Some "name"

# Content_disposition.find_param t "param1" ;;
- : string option = None
```

## Content_disposition.make/encode

```ocaml
# let t = Content_disposition.make ~params:[("filename", "\"hello world.png\""); ("name", "\"field1\"")] "form-data";;
val t : Content_disposition.t = <abstr>

# Content_disposition.encode t ;;
- : string = "form-data; filename=\"hello world.png\"; name=\"field1\""
```
