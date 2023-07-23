# Host

```ocaml
open Spring
```

## decode

Decode both host and port.

```ocaml
# let t0 = Host.decode "192.168.0.1:8080";;
val t0 : Host.t = (`IPv4 <abstr>, Some 8080)
```

Decode host only.

```ocaml
# let t1 = Host.decode "192.168.0.1";;
val t1 : Host.t = (`IPv4 <abstr>, None)
```

## encode

```ocaml
# Host.encode t0;;
- : string = "192.168.0.1:8080"

# Host.encode t1;;
- : string = "192.168.0.1"
```

## equal

```ocaml
# Host.equal t0 t1;;
- : bool = false

# Host.equal t0 t0;;
- : bool = true

# Host.equal t1 t1;;
- : bool = true
```

## pp

```ocaml
# Eio.traceln "%a" Host.pp t0;;
+IPv4 192.168.0.1:8080
- : unit = ()

# Eio.traceln "%a" Host.pp t1;;
+IPv4 192.168.0.1:
- : unit = ()
```
