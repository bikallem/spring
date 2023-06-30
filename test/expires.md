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
let clock = Eio_mock.Clock.make ()
let _ = Eio_mock.Clock.set_time clock 1623940778.27033591
```

```ocaml
# let e = Expires.of_date @@ Date.now clock;;
val e : Expires.t = <abstr>

# Expires.is_expired e;;
- : bool = false

# Eio.traceln "%a" Expires.pp e;;
+Thu, 17 Jun 2021 14:39:38 GMT
- : unit = ()
```

