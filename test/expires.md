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
