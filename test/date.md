# Date tests

```ocaml
open Spring
```

## Date.decode

```ocaml
# let date1 = Date.decode "Sun, 06 Nov 1994 08:49:37 GMT";;
val date1 : Date.t = <abstr>

# Eio.traceln "%a" Date.pp date1 ;;
+Sun, 06 Nov 1994 08:49:37 GMT
- : unit = ()

# let date2 = Date.decode "Sunday, 06-Nov-94 08:49:37 GMT";;
val date2 : Date.t = <abstr>

# Eio.traceln "%a" Date.pp date2 ;;
+Sun, 06 Nov 1994 08:49:37 GMT
- : unit = ()

# let date3 = Date.decode "Sun Nov  6 08:49:37 1994";;
val date3 : Date.t = <abstr>

# Eio.traceln "%a" Date.pp date3 ;;
+Sun, 06 Nov 1994 08:49:37 GMT
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
# Date.now mock_clock |> Eio.traceln "%a" Date.pp;; 
+Mon, 24 Oct 2022 16:12:15 GMT
- : unit = ()
```

## Date.of_ptime/of_float_s/equal/compare/is_later/is_earlier

```ocaml
let now = 1623940778.27033591
```

`Date.t` created using same value `now` are equal.

```ocaml

# let p = Ptime.of_float_s now |> Option.get;;
val p : Ptime.t = <abstr>

# let d1 = Date.of_ptime p ;;
val d1 : Date.t = <abstr>

# let d2 = Date.of_float_s now |> Option.get;;
val d2 : Date.t = <abstr>

# Date.equal d1 d2;;
- : bool = true

# Date.compare d1 d2;;
- : int = 0

# Date.is_later d1 ~than:d2, Date.is_later d2 ~than:d1;;
- : bool * bool = (false, false)

# Date.is_earlier d1 ~than:d2, Date.is_earlier d2 ~than:d1;;
- : bool * bool = (false, false)
```

`Date.t` created later returns `true` when comparing `is_later/is_earlier` with `d3`.

```ocaml
# let d3 = Date.of_ptime @@ Ptime_clock.now ();;
val d3 : Date.t = <abstr>

# Date.is_later d3 ~than:d1, Date.is_later d3 ~than:d2;;
- : bool * bool = (true, true)

# Date.is_earlier d1 ~than:d3, Date.is_earlier d1 ~than:d3;;
- : bool * bool = (true, true)
```

## equal 

Decoding a value, encoding and decoding it back. `Date.t` should be equal.

```ocaml
# let v1 = "Thu, 17 Jun 2021 14:39:38 GMT";;
val v1 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# let dd1 = Date.decode v1;; 
val dd1 : Date.t = <abstr>

# let v2 = Date.encode dd1;;
val v2 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# String.equal v1 v2;;
- : bool = true

# let dd2 = Date.decode v2;;
val dd2 : Date.t = <abstr>

# Date.equal dd1 dd2
- : bool = true

# Date.compare dd1 dd2;;
- : int = 0
```
