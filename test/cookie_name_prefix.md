# Cookie_name_prefix

```ocaml
open Spring
```

## host/secure/to_string/pp

Display cookie name prefix values.

```ocaml
# Cookie_name_prefix.(host |> to_string) ;;
- : string = "__Host-"

# Eio.traceln "%a" Cookie_name_prefix.pp Cookie_name_prefix.secure;;
+__Secure-
- : unit = ()
```

## equal/compare

```ocaml
# Cookie_name_prefix.(equal host secure, compare host secure);;
- : bool * int = (false, -1)

# Cookie_name_prefix.(equal host host, compare host host);;
- : bool * int = (true, 0)

# Cookie_name_prefix.(equal secure secure, compare secure secure);;
- : bool * int = (true, 0)
```

## cut_prefix

```ocaml
let display_cut_result ((name1,t1), (name2, t2)) =
  let pp = Fmt.(option ~none:(any "None") Cookie_name_prefix.pp) in
  Eio.traceln "(%s, %a) (%s, %a)" name1 pp t1 name2 pp t2
```

Case sensitive match is the default.

```ocaml
# Cookie_name_prefix.(
    cut_prefix "__Host-SID", 
    cut_prefix ~case_sensitive:true "__HoST-SID")
    |> display_cut_result2 ;;
Line 4, characters 8-27:
Error: Unbound value display_cut_result2
Hint: Did you mean display_cut_result?

# Cookie_name_prefix.(
  cut_prefix "__Secure-SID", 
  cut_prefix ~case_sensitive:true "__SeCUre-SID")
  |> display_cut_result ;;
+(SID, __Secure-) (__SeCUre-SID, None)
- : unit = ()
```

Case in-sensitive cut.

```ocaml
# Cookie_name_prefix.(
  cut_prefix ~case_sensitive:false "__Host-SID",
  cut_prefix ~case_sensitive:false "__HOst-SID")
  |> display_cut_result ;;
+(SID, __Host-) (SID, __Host-)
- : unit = ()

# Cookie_name_prefix.(
  cut_prefix ~case_sensitive:false "__Secure-SID",
  cut_prefix ~case_sensitive:false "__SECuRe-SID")
  |> display_cut_result ;;
+(SID, __Secure-) (SID, __Secure-)
- : unit = ()
```

Prefix not matched

```ocaml
# Cookie_name_prefix.cut_prefix "__HelloSID";;
- : string * Cookie_name_prefix.t option = ("__HelloSID", None)
```
