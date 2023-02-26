# Date tests

```ocaml
open Spring
```

## Date.decode

```ocaml
# let date1 = Date.decode "Sun, 06 Nov 1994 08:49:37 GMT";;
val date1 : Ptime.t = <abstr>

# Eio.traceln "%a" Ptime.pp date1 ;;
+1994-11-06 08:49:37 +00:00
- : unit = ()

# let date2 = Date.decode "Sunday, 06-Nov-94 08:49:37 GMT";;
val date2 : Ptime.t = <abstr>

# Eio.traceln "%a" Ptime.pp date2 ;;
+1994-11-06 08:49:37 +00:00
- : unit = ()

# let date3 = Date.decode "Sun Nov  6 08:49:37 1994";;
+m:11, d:6
+y
val date3 : Ptime.t = <abstr>

# Eio.traceln "%a" Ptime.pp date3 ;;
+1994-11-06 08:49:37 +00:00
- : unit = ()
```

## Date.encode

```ocaml
# Date.encode date1;;
- : string = "Sun, 06 Nov 1994 08:49:37 GMT"

# Date.encode date2;;
- : string = "Sun, 06 Nov 1994 08:49:37 GMT"

# Date.encode date3;;
- : string = "Sun, 06 Nov 1994 08:49:37 GMT"
```
