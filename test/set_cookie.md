# Set_cookie tests

```ocaml
open Spring
```

## Set_cookie.decode

```ocaml
# let t = Set_cookie.decode "lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT"
val t : Set_cookie.t = <abstr>
```
## Set_cooki.name

```ocaml
# Set_cookie.name t ;;
- : string = "lang"
```

## Set_cookie.value

```ocaml
# Set_cookie.value t;;
- : string = "en-US"
```

## Set_cookie.expires

```ocaml
# Set_cookie.expires t |> Option.get |> Eio.traceln "%a" Ptime.pp ;;
+2021-06-09 10:18:14 +00:00
- : unit = ()
```

