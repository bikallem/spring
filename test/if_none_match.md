# If_none_match tests

```ocaml
open Spring
```

Any value.

```ocaml
# let any = If_none_match.any;;
val any : If_none_match.t = <abstr>

# If_none_match.is_any any;;
- : bool = true
```

## make/contains_entity_tag.

```ocaml
# let etag1 =Etag.make "xyzzy" and etag2 = Etag.make ~weak:true "xyzzy" ;;
val etag1 : Etag.t = <abstr>
val etag2 : Etag.t = <abstr>

# let etags = [etag1; etag2] ;;
val etags : Etag.t list = [<abstr>; <abstr>]

# let t = If_none_match.make etags;;
val t : If_none_match.t = <abstr>

# If_none_match.contains_entity_tag (fun etag -> Etag.weak_equal etag etag2) t ;;
- : bool = true

# If_none_match.contains_entity_tag (fun etag -> Etag.strong_equal etag etag2) t ;;
- : bool = false

# If_none_match.contains_entity_tag (fun etag -> Etag.strong_equal etag etag1) t ;;
- : bool = true
```

Searching for entity tag in [any t = true] is always true.

```ocaml
# If_none_match.contains_entity_tag (fun _ -> false) any;;
- : bool = true
```

Empty entity_tags is invalild.

```ocaml
# If_none_match.make [];;
Exception: Invalid_argument "[entity_tags] is empty".
```

## entity_tags

Retrieve entity tags.

```ocaml
# If_none_match.entity_tags t = Some etags;;
- : bool = true
```

## decode

Decode a strong etag value.

```ocaml
# let t1 = If_none_match.decode {|"c3piozzzz"|};;
val t1 : If_none_match.t = <abstr>

# If_none_match.entity_tags t1 
  |> Option.get
  |> List.iter (fun etag -> Eio.traceln "%s" (Etag.encode etag)) ;;
+"c3piozzzz"
- : unit = ()
```

Decode a weak etag value.

```ocaml
# let t2 = If_none_match.decode {|W/"xyzzy"|};;
val t2 : If_none_match.t = <abstr>

# If_none_match.entity_tags t2 
  |> Option.get
  |> List.iter (fun etag -> Eio.traceln "%s" (Etag.encode etag)) ;;
+W/"xyzzy"
- : unit = ()
```

Decode a list of strong etag values.

```ocaml
# let t3 = If_none_match.decode {|"xyzzy", "r2d2xxxx", "c3piozzzz"|};; 
val t3 : If_none_match.t = <abstr>

# If_none_match.entity_tags t3
  |> Option.get
  |> List.iter (fun etag -> Eio.traceln "%s" (Etag.encode etag)) ;;
+"xyzzy"
+"r2d2xxxx"
+"c3piozzzz"
- : unit = ()
```

Decode a list of weak etag values.

```ocaml
# let t4 = If_none_match.decode {|W/"xyzzy", W/"r2d2xxxx", W/"c3piozzzz"|};; 
val t4 : If_none_match.t = <abstr>

# If_none_match.entity_tags t4
  |> Option.get
  |> List.iter (fun etag -> Eio.traceln "%s" (Etag.encode etag)) ;;
+W/"xyzzy"
+W/"r2d2xxxx"
+W/"c3piozzzz"
- : unit = ()
```

Decode a list of weak and strong etag values.

```ocaml
# let t5 = If_none_match.decode {|"xyzzy", W/"r2d2xxxx", "c3piozzz", W/"c3piozzzz"|};; 
val t5 : If_none_match.t = <abstr>

# If_none_match.entity_tags t5
  |> Option.get
  |> List.iter (fun etag -> Eio.traceln "%s" (Etag.encode etag)) ;;
+"xyzzy"
+W/"r2d2xxxx"
+"c3piozzz"
+W/"c3piozzzz"
- : unit = ()
```

Decode '*'.

```ocaml
# let any1 = If_none_match.decode "*";;
val any1 : If_none_match.t = <abstr>

# If_none_match.is_any any1;;
- : bool = true
```

Invalid values.

```ocaml
# If_none_match.decode "**";;
Exception: Invalid_argument "[s] contains invalid [If-None-Match] value".

# If_none_match.decode {| "xyzzy",|};;
Exception: Invalid_argument "[v] contains invalid ETag value".
```

## encode

```ocaml
# If_none_match.encode any;;
- : string = "*"

# If_none_match.encode any1;; 
- : string = "*"

# If_none_match.encode t1;;
- : string = "\"c3piozzzz\""

# If_none_match.encode t2;;
- : string = "W/\"xyzzy\""

# If_none_match.encode t3;;
- : string = "\"xyzzy\", \"r2d2xxxx\", \"c3piozzzz\""

# If_none_match.encode t4;;
- : string = "W/\"xyzzy\", W/\"r2d2xxxx\", W/\"c3piozzzz\""

# If_none_match.encode t5;;
- : string = "\"xyzzy\", W/\"r2d2xxxx\", \"c3piozzz\", W/\"c3piozzzz\""
```
