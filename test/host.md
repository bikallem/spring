# Host

```ocaml
open Spring
```

## decode

Decode IPv6 host and port.

```ocaml
# let t0 = Host.decode "192.168.0.1:8080";;
val t0 : Host.t = <abstr>

# Eio.traceln "%a" Host.pp t0;;
+IPv4 192.168.0.1:8080
- : unit = ()
```

Decode IPv4 host only.

```ocaml
# let t1 = Host.decode "192.168.0.1";;
val t1 : Host.t = <abstr>

# Eio.traceln "%a" Host.pp t1;;
+IPv4 192.168.0.1:
- : unit = ()
```

Decode domain name.

```ocaml
# let t2 = Host.decode "www.example.com:8080";;
val t2 : Host.t = <abstr>

# Eio.traceln "%a" Host.pp t2;;
+Domain www.example.com:8080
- : unit = ()
```

Decode IPv6 host and port.

```ocaml
# let t3 = Host.decode "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]:8080";;
val t3 : Host.t = <abstr>
```

## encode

```ocaml
# Host.encode t0;;
- : string = "192.168.0.1:8080"

# Host.encode t1;;
- : string = "192.168.0.1"

# Host.encode t2;;
- : string = "www.example.com:8080"

# Host.encode t3;;
- : string = "2001:db8:aaaa:bbbb:cccc:dddd:eeee:1:8080"
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

# Host.equal t3 t3;;
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

# Host.compare t3 t3;;
- : int = 0

# Host.compare t3 t0;;
- : int = 1

# Host.compare t3 t1;;
- : int = 1

# Host.compare t3 t2;;
- : int = 1
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

# Eio.traceln "%a" Host.pp t3;;
+IPv6 2001:db8:aaaa:bbbb:cccc:dddd:eeee:1:8080
- : unit = ()
```
