# Cache-Control

```ocaml
open Spring
```

## make_bool_directive

```ocaml
# let d = Cache_control.Directive.make_bool_directive "no-cache";;
val d : Cache_control.Directive.bool' = <abstr>

# Cache_control.Directive.name d;;
- : string = "no-cache"

# Cache_control.Directive.decode d;;
- : bool Cache_control.Directive.decode option = None

# Cache_control.Directive.encode d;;
- : bool Cache_control.Directive.encode option = None

# Cache_control.Directive.is_bool d;;
- : bool = true
```

## make 

```ocaml
# let d1 = Cache_control.Directive.make "max-age" int_of_string string_of_int;;
val d1 : int Cache_control.Directive.t = <abstr>

# Cache_control.Directive.name d1;;
- : string = "max-age"

# Cache_control.Directive.is_bool d1;;
- : bool = false
```

## add/find_opt/find

Add and find `max_age` directive.

```ocaml
# Cache_control.(find_opt max_age empty);;
- : int option = None

# let t1 = Cache_control.(add ~v:5 max_age empty);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt max_age t1);;
- : int option = Some 5
```

Adding with `[v = None]` for non bool directive results in `Invalid_arg` exception.

```ocaml
# Cache_control.(add max_age empty);;
Exception:
Invalid_argument "[v] is [None] but is required for non bool directives".
```

Add and find `no-cache` directive.

```ocaml
# Cache_control.(find_opt no_cache t1);;
- : bool option = None

# Cache_control.(find no_cache t1);;
- : bool = false

# let t1 = Cache_control.(add no_cache t1);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt no_cache t1);;
- : bool option = Some true

# Cache_control.(find no_cache t1);;
- : bool = true
```

Parameter `[v]` is ignored when adding bool directives. 

```ocaml
# let t1 = Cache_control.(add ~v:false no_cache empty);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find_opt no_cache t1);;
- : bool option = Some true

# Cache_control.(find no_cache t1);;
- : bool = true
```

## decode

```ocaml
let s ={|max-age=604800, must-revalidate, no-store, private, public, custom1="val1"|};;
```

```ocaml
# let t2 = Cache_control.decode s;
val t2 : Cache_control.t = <abstr>

# Cache_control.(find_opt max_age t2);;
- : int option = Some 604800

# Cache_control.decode "";;
Exception: Failure "take_while1".
```

Decoding correctly takes whitespaces before/after `,'.

```ocaml
# Cache_control.decode "max-age=604800,    must-revalidate, no-store,private   , public";;
- : Cache_control.t = <abstr>
```

## encode

```ocaml
# let s1 = Cache_control.encode t2;;
val s1 : string =
  "max-age=604800, must-revalidate, no-store, private, public, custom1=\"val1\""

# s1 = s;;
- : bool = true
```
