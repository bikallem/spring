# Host

```ocaml
open Spring
```

## decode

Decode both host and port.

```ocaml
# Host.decode "192.168.0.1:8080" |> Eio.traceln "%a" Host.pp;;
+IPv4 192.168.0.1:8080
- : unit = ()
```

Decode host only.

```ocaml
# Host.decode "192.168.0.1";;
```
