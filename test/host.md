# Host

```ocaml
open Spring
```

## decode

Decode both host and port.

```ocaml
# let t1 = Host.decode "192.168.0.1:8080";;
val t1 : Host.t = (`IPv4 <abstr>, Some 8080)
```

Decode host only.

```ocaml
# let t2 = Host.decode "192.168.0.1";;
val t2 : Host.t = (`IPv4 <abstr>, None)
```

## encode

```ocaml
# Host.encode t1;;
- : string = "192.168.0.1:8080"

# Host.encode t2;;
- : string = "192.168.0.1"
```

## pp

```ocaml
# Eio.traceln "%a" Host.pp t1;;
+IPv4 192.168.0.1:8080
- : unit = ()

# Eio.traceln "%a" Host.pp t2;;
+IPv4 192.168.0.1:
- : unit = ()
```
