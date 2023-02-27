# Set_cookie tests

```ocaml
open Spring
```

## Set_cookie.decode

```ocaml
# let t = Set_cookie.decode "lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT; Max-Age=2"
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

## Set_cookie.max_age

```ocaml
# Set_cookie.max_age t;;
- : int option = Some 2
```

## Set_cookie.domain

```ocaml
# let t = Set_cookie.decode "d=d; Domain=www.example.com";;
val t : Set_cookie.t = <abstr>

# Set_cookie.domain t |> Option.get |> Eio.traceln "%a" Domain_name.pp ;;
+www.example.com
- : unit = ()

# let t = Set_cookie.decode "d=d; Domain=example.org";;
val t : Set_cookie.t = <abstr>

# Set_cookie.domain t |> Option.get |> Eio.traceln "%a" Domain_name.pp ;;
+example.org
- : unit = ()
```

Host only. 

```ocaml
# let t = Set_cookie.decode "d=d; Domain=example-host";;
val t : Set_cookie.t = <abstr>

# Set_cookie.domain t |> Option.get |> Eio.traceln "%a" Domain_name.pp ;;
+example-host
- : unit = ()
```


