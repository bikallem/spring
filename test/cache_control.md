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
# let d1 = Cache_control.Directive.make "max-age" int_of_string string_of_int Fmt.int;;
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

## exists

```ocaml
# Cache_control.(exists no_cache t1);;
- : bool = true

# Cache_control.(exists max_age t1);;
- : bool = false
```

## remove

```ocaml
# Cache_control.(find no_cache t1);;
- : bool = true

# let t1 = Cache_control.(remove no_cache t1);;
val t1 : Cache_control.t = <abstr>

# Cache_control.(find no_cache t1);;
- : bool = false
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
```

Decoding correctly decodes redundant whitespaces before/after `,'.

```ocaml
# Cache_control.decode "max-age=604800,    must-revalidate, no-store,private   , public";;
- : Cache_control.t = <abstr>
```

Exception when the decode value is empty.

```
# Cache_control.decode "";;
Exception: Failure "take_while1".
```

Exception when name-value directive is missing a value after `=`.

```ocaml
# Cache_control.decode "max-age=";; 
Exception: Failure "[cache_directive: max-age] value missing after '='".
```

## encode

```ocaml
# let s1 = Cache_control.encode t2;;
val s1 : string =
  "max-age=604800, must-revalidate, no-store, private, public, custom1=\"val1\""

# s1 = s;;
- : bool = true
```

## pp

```ocaml
# Eio.traceln "%a" Cache_control.pp t2;;
+max-age=604800, must-revalidate, no-store, private, public, custom1="val1"
- : unit = ()
```

## equal

```ocaml
# Cache_control.equal t2 t2;;
- : bool = true

# Cache_control.equal t2 t1;;
- : bool = false

# Cache_control.(equal empty empty);;
- : bool = true

# Cache_control.(equal t1 empty);;
- : bool = true
```

## Full lifecycle - decode, encode, decode, equal

1. decode a cache-control value to `cc1`
2. encode `cc1` to `s2`
3. decode `cc2` from `s2`
4. `cc1` and `cc2` should be equal

```ocaml
# let cc1 = Cache_control.decode s1;;
val cc1 : Cache_control.t = <abstr>

# let s2 = Cache_control.encode cc1;;
val s2 : string =
  "max-age=604800, must-revalidate, no-store, private, public, custom1=\"val1\""

# let cc2 = Cache_control.decode s1;;
val cc2 : Cache_control.t = <abstr>

# Cache_control.equal cc1 cc2;;
- : bool = true
```

## Standard Directives

Test the directive as follows:

1. Print name.
2. Print is_bool.
3. If a bool directive, then do 4 - 6.
4. decode s1 to v1.
5. encode v1 to s2.
5. decode s2 to v2.
6. ensure v1 and v2 equal. 

```ocaml
let test_name_val s1 d =
    let decode = Cache_control.Directive.decode d |> Option.get in
    let encode = Cache_control.Directive.encode d |> Option.get in
    let v1 = decode s1 in
    let s2 = encode v1 in
    let v2 = decode s2 in
    Eio.traceln "s1: %s, s2: %s" s1 s2;
    Eio.traceln "(v1 = v2) -> %b" (v1 = v2)

let test_directive ?v d =
    Eio.traceln "name: %s" @@ Cache_control.Directive.name d;
    let is_bool = Cache_control.Directive.is_bool d in
    Eio.traceln "is_bool: %b" @@ is_bool;
    if is_bool then ()
    else test_name_val (Option.get v) d
```

max-age.

```ocaml
# test_directive ~v:"5" Cache_control.max_age;;
+name: max-age
+is_bool: false
+s1: 5, s2: 5
+(v1 = v2) -> true
- : unit = ()
```

max-stale.

```ocaml
# test_directive ~v:"2333" Cache_control.max_stale
+name: max-stale
+is_bool: false
+s1: 2333, s2: 2333
+(v1 = v2) -> true
- : unit = ()
```
