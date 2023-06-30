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
let now = ref 1623940778.27033591

let fake_clock = object (_ : #Eio.Time.clock)
  method now = !now
  method sleep_until _time = failwith "not implemented"
end
```

```ocaml
# let e = Expires.of_date @@ Date.now fake_clock;;
val e : Expires.t = <abstr>

# Expires.is_expired e;;
- : bool = false

# Eio.traceln "%a" Expires.pp e;;
+Thu, 17 Jun 2021 14:39:38 GMT
- : unit = ()
```

