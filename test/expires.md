# Expires tests

```ocaml
open Spring
```

## expired/is_expired/expired_value

1. An expired value returns `true` for `is_expired`.
2. Expires.expired value is encoded as `0`.
2. An expired value `ed` is any invalid HTTP Date.t value.
3. Two expired values with two different invalid HTTP Date.t values are equal.

```ocaml
# Expires.(is_expired expired);;
- : bool = true

# Expires.(expired_value expired);;
- : string option = Some "0"

# let ed = Expires.decode "-1";;
val ed : Expires.t = <abstr>

# Expires.is_expired ed;;
- : bool = true

# Expires.(equal ed expired);;
- : bool = true
```

## pp

```ocaml
# Eio.traceln "%a" Expires.pp Expires.expired;;
+0
- : unit = ()
```

## of_date

```ocaml
let now = 1623940778.27033591 
let clock = Eio_mock.Clock.make ()
let () = Eio_mock.Clock.set_time clock now
```

1. Create a `now` Date.t value.
2. Create `e` as Expires.t from `now`.
3. Display `e` properties.
4. Encode `e` to `s1`.
5. Decode `s1` to `e2`.
6. `e` and `e2` is equal.
7. Expires.date `e` and `now` is equal since they are both the same Date.t value.

```ocaml
# let now = Date.now clock ;;
val now : Date.t = <abstr>

# let e = Expires.of_date now;;
val e : Expires.t = <abstr>

# Expires.is_expired e;;
- : bool = false

# let s1 = Expires.encode e;;
val s1 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# let e2 = Expires.decode s1;;
val e2 : Expires.t = <abstr>

# Expires.equal e e2;;
- : bool = true

# Expires.date e |> Option.get = now;;
- : bool = true
```

## decode/encode

```ocaml
# let s1 = "Thu, 17 Jun 2021 14:39:38 GMT";;
val s1 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# let e1 = Expires.decode s1;;
val e1 : Expires.t = <abstr>

# let s2 = Expires.encode e1;;
val s2 : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# String.equal s1 s2;;
- : bool = true

# let e2 = Expires.decode s2;;
val e2 : Expires.t = <abstr>

# Expires.equal e1 e2;;
- : bool = true
```

## equal

```ocaml
# Expires.equal e1 e2;; 
- : bool = true

# Expires.equal e e;;
- : bool = true

# Expires.(equal expired expired);;
- : bool = true

# Expires.equal e e1;;
- : bool = true
```
