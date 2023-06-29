# Cache-Control

```ocaml
open Spring
```

## add

```ocaml
# Cache_control.(find_opt max_age empty);;
- : int option = None

# let t1 = Cache_control.(add ~v:5 max_age empty);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt max_age t1);;
- : int option = Some 5

# Cache_control.(find_opt no_cache t1);;
- : bool option = None

# let t1 = Cache_control.(add no_cache t1);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt no_cache t1);;
- : bool option = Some true
```
