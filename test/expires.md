# Expires tests

```ocaml
open Spring
```

## expired/is_expired

An expired value returns `true` for `is_expired`.

```ocaml
# Expires.(is_expired expired);;
- : bool = true
```

## pp

```ocaml
# Eio.traceln "%a" Expires.pp Expires.expired;;
+0
- : unit = ()
```

## of_date

```ocaml
let now = 1623940778.27033591 
let clock = Eio_mock.Clock.make ()
let () = Eio_mock.Clock.set_time clock now
```

```ocaml
# let e = Expires.of_date @@ Date.now clock;;
val e : Expires.t = <abstr>

# Expires.is_expired e;;
- : bool = false

# let s1 = Expires.encode e;;
val s1 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# let e2 = Expires.decode s1;;
val e2 : Expires.t = <abstr>

# Expires.equal e e2;;
- : bool = true
```

## decode/encode

```ocaml
# let s1 = "Thu, 17 Jun 2021 14:39:38 GMT";;
val s1 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# let e1 = Expires.decode s1;;
val e1 : Expires.t = <abstr>

# let s2 = Expires.encode e1;;
val s2 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# String.equal s1 s2;;
- : bool = true

# let e2 = Expires.decode s2;;
val e2 : Expires.t = <abstr>
```

## equal

```ocaml
# Expires.equal e1 e2;; 
- : bool = true

# Expires.equal e e;;
- : bool = true

# Expires.(equal expired expired);;
- : bool = true

# Expires.equal e e1;;
- : bool = true
```
