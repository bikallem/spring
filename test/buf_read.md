# Spring.Buf_read

```ocaml
open Spring

module Buf_read = Spring__Buf_read

let b s = Buf_read.of_string s
```

## Buf_read.take_while1

`take_while1` calls given `on_error` function.

```ocaml
# Buf_read.take_while1 ~on_error:(fun () -> failwith "invalid name")
    (function 'a'..'z' -> true | _ -> false) @@ b "";;
Exception: Failure "invalid name".
```

## Buf_read.quoted_pair

```ocaml
# Buf_read.quoted_pair @@ b {|\"|} ;;
- : char = '"'

# Buf_read.quoted_pair @@ b {|\\|} ;;
- : char = '\\'

# Buf_read.quoted_pair @@ b {|\v|} ;;
- : char = 'v'
```

## Buf_read.quoted_text

```ocaml
# Buf_read.quoted_text @@ b "\t";;
- : char = '\t'

# Buf_read.quoted_text @@ b "a";;
- : char = 'a'
```

## Buf_read.quoted_string

```ocaml
# Buf_read.quoted_string @@ b {|"hello world"|} ;;
- : string = "hello world"

# Buf_read.quoted_string @@ b {|"hello \" \\world"|} ;;
- : string = "hello \" \\world"
```

## list1 

`list1` should parse at least one or more elements. 

Valid cases.

```ocaml
# let p = Buf_read.take_while1 (function 'a' .. 'z' -> true | _ -> false);;
val p : string Buf_read.parser = <fun>

# Buf_read.list1 p (Buf_read.of_string "foo, bar");;
- : string list = ["foo"; "bar"]

# Buf_read.list1 p (Buf_read.of_string "foo ,bar,");;
- : string list = ["foo"; "bar"]

# Buf_read.list1 p (Buf_read.of_string "foo , ,bar,charlie");;
- : string list = ["foo"; "bar"; "charlie"]
```

Invalid cases - `take_while1` requires at least one character.

```ocaml
# Buf_read.list1 p (Buf_read.of_string "");;
Exception: Failure "take_while1".

# Buf_read.list1 p (Buf_read.of_string ",");;
Exception: Failure "take_while1".

# Buf_read.list1 p (Buf_read.of_string ",    ,");;
Exception: Failure "take_while1".
```

Valid cases - `take_while` allows empty string.

```ocaml
# let p = Buf_read.take_while (function 'a' .. 'z' -> true | _ -> false);;
val p : string Buf_read.parser = <fun>

# Buf_read.list1 p (Buf_read.of_string "");;
- : string list = [""]

# Buf_read.list1 p (Buf_read.of_string ",");;
- : string list = [""]

# Buf_read.list1 p (Buf_read.of_string ",    ,");;
- : string list = [""]
```

## delta_seconds

```ocaml
# Buf_read.(delta_seconds (of_string "234"));;
- : int = 234

# Buf_read.(delta_seconds (of_string "5"));;
- : int = 5

# Buf_read.(delta_seconds (of_string ""));;
Exception: Failure "take_while1".
```
