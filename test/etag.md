# Etag tests

```ocaml
open Spring
```

Strong ETag value.

```ocaml
# let etag1 = Etag.decode {|"xyzzy"|};;
val etag1 : Etag.t = <abstr>

# Etag.is_weak etag1;;
- : bool = false

# Etag.is_strong etag1;;
- : bool = true

# Etag.chars etag1;;
- : string = "xyzzy"

# Etag.encode etag1;;
- : string = "\"xyzzy\""
```

Weak ETag value.

```ocaml
# let etag2 = Etag.decode {|W/"xyzzy"|};;
val etag2 : Etag.t = <abstr>

# Etag.is_weak etag2;;
- : bool = true

# Etag.is_strong etag2;;
- : bool = false

# Etag.chars etag2;;
- : string = "xyzzy"

# Etag.encode etag2;;
- : string = "W/\"xyzzy\""
```

Decode empty string.

```ocaml
# Etag.decode {|""|};;
- : Etag.t = <abstr>
```

Etag.equal.

```ocaml
# Etag.strong_equal etag1 etag2;;
- : bool = false

# Etag.strong_equal etag2 etag1;;
- : bool = false

# Etag.strong_equal etag1 (Etag.make "xyzzy" );;
- : bool = true

# Etag.weak_equal etag1 etag2;;
- : bool = true

# Etag.weak_equal etag2 etag1;;
- : bool = true
```

Invalid ETag value.

```ocaml
# Etag.decode {|"adasdf"aa|};;
Exception: Invalid_argument "[v] contains invalid ETag value".

# Etag.decode {|"asdfasd "|} ;;
Exception: Failure "Expected '\"' but got ' '".
```
