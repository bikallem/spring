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

## Date.now 

```ocaml
let mock_clock = Eio_mock.Clock.make ()
let () = Eio_mock.Clock.set_time mock_clock 1666627935.85052109
```

```ocaml
# Date.now mock_clock |> Eio.traceln "%a" Ptime.pp;; 
+2022-10-24 16:12:15 +00:00
- : unit = ()
```

## Date.of_ptime

```ocaml
# let p = Ptime_clock.now ();;
val p : Ptime.t = <abstr>

# let d1 = Date.of_ptime p;;
val d1 : Ptime.t = <abstr>

# let d2 = Date.of_ptime p;;
val d2 : Ptime.t = <abstr>

# Date.equal d1 d2;;
- : bool = true

# Date.compare d1 d2;;
- : int = 0
```
