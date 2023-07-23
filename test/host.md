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

Decode domain name.

```ocaml
# let t2 = Host.decode "www.example.com:8080";;
val t2 : Host.t = (`Domain_name <abstr>, Some 8080)
```

## encode

```ocaml
# Host.encode t0;;
- : string = "192.168.0.1:8080"

# Host.encode t1;;
- : string = "192.168.0.1"

# Host.encode t2;;
- : string = "www.example.com:8080"
```

## equal

```ocaml
# Host.equal t0 t1;;
- : bool = false

# Host.equal t0 t0;;
- : bool = true

# Host.equal t1 t1;;
- : bool = true

# Host.equal t2 t2;;
- : bool = true
```

## compare

```ocaml
# Host.compare t0 t0;;
- : int = 0

# Host.compare t0 t1;;
- : int = 1

# Host.compare t0 t2;;
- : int = 1

# Host.compare t1 t1;;
- : int = 0

# Host.compare t1 t0;;
- : int = -1

# Host.compare t1 t2;;
- : int = 1

# Host.compare t2 t2;;
- : int = 0

# Host.compare t2 t0;;
- : int = -1

# Host.compare t2 t1;;
- : int = -1
```

## pp

```ocaml
# Eio.traceln "%a" Host.pp t0;;
+IPv4 192.168.0.1:8080
- : unit = ()

# Eio.traceln "%a" Host.pp t1;;
+IPv4 192.168.0.1:
- : unit = ()

# Eio.traceln "%a" Host.pp t2;;
+Domain www.example.com:8080
- : unit = ()
```
