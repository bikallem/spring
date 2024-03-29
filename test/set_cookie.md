# Set_cookie tests

```ocaml
open Spring
```

Function to display a few `Set_cookie.t` properties.

```ocaml
let display_set_cookie_details t =
    Eio.traceln "name: %s" (Set_cookie.name t);
    Eio.traceln "value: '%s'" (Set_cookie.value t);
    match Set_cookie.extension t with
    | Some v -> Eio.traceln "extension: '%s'" v
    | None -> ()
```

# make

1. Make a `Set-Cookie` value `t` with extension parameter.
2. Display name
3. Display value
4. Display extension value.

```ocaml
# let t = Set_cookie.make ~extension:"hello" ~name:"cookie1" "val1";;
val t : Set_cookie.t = <abstr>

# display_set_cookie_details t;;
+name: cookie1
+value: 'val1'
+extension: 'hello'
- : unit = ()
```

Set-Cookie can't have empty `name`.

```ocaml
# Set_cookie.make ~name:"" "v";;
Exception: Invalid_argument "[name] is invalid. take_while1 (at offset 0)".
```

`make` validates the `name` parameter.

```ocaml
# Set_cookie.make ~name:"asdf asdfas" "123";;
Exception:
Invalid_argument
 "[name] is invalid. Unexpected data after parsing (at offset 4)".
```

`make` validates the `extension` parameter.

```ocaml
# Set_cookie.make ~extension:"asdfas;" ~name:"SID" "123";;
Exception:
Invalid_argument
 "[extension] is invalid. Unexpected data after parsing (at offset 6)".
```

`make` validates `value` parameter. `,` is now allowed in value.

```ocaml
# Set_cookie.make ~name:"SID" "23ab,asdasd";;
Exception:
Invalid_argument
 "[value] is invalid. Unexpected data after parsing (at offset 4)".
```

## decode

1. Decode Set-Cookie from various strings.
2. Display decoded Set-Cookie details.

```ocaml
# let t = Set_cookie.decode "asdfa=asdfasdf";;
val t : Set_cookie.t = <abstr>

# display_set_cookie_details t;;
+name: asdfa
+value: 'asdfasdf'
- : unit = ()
```

Double quoted Set-Cookie values are part of the value and are not stripped.

```ocaml
# let t = Set_cookie.decode {|name1="value=@>?"|};;
val t : Set_cookie.t = <abstr>

# display_set_cookie_details t;;
+name: name1
+value: '"value=@>?"'
- : unit = ()

# Set_cookie.encode t;;
- : string = "name1=\"value=@>?\""
```

Ensure whitespaces are correctly parsed.

```ocaml
# Set_cookie.decode {|name1  =  "value=@>?"|} |> display_set_cookie_details;;
+name: name1
+value: '"value=@>?"'
- : unit = ()
```

Process cookie-name prefix `__Host-` in `Set-Cookie` name.

```ocaml
let display_set_cookie_attributes t =
  let pp = Fmt.(option ~none:(any "None") Cookie_name_prefix.pp) in
  Eio.traceln "Name : %s" @@ Set_cookie.name t;
  Eio.traceln "NamePrefix: %a" pp @@ Set_cookie.name_prefix t;
  Eio.traceln "Secure : %b" @@ Set_cookie.(find secure t);
  (match Set_cookie.(find_opt path t) with
  | Some p -> Eio.traceln "Path: '%s'" p
  | None -> ());
  (match Set_cookie.(find_opt domain t) with
  | Some dn -> Eio.traceln "Domain : %a" Domain_name.pp dn
  | None -> ())
```

```ocaml
# Set_cookie.decode "__Host-SID=12333" |> display_set_cookie_attributes;;
+Name : SID
+NamePrefix: __Host-
+Secure : false
- : unit = ()
```

Process cookie-name prefix `__Secure-` in `Set-Cookie` name.

```ocaml
# Set_cookie.decode "__Secure-SID=12333;Domain=www.example.com" |> display_set_cookie_attributes;;
+Name : SID
+NamePrefix: __Secure-
+Secure : false
+Domain : www.example.com
- : unit = ()
```

Set `process_name_prefix` parameter to `false`.

```ocaml
# Set_cookie.decode "__Secure-SID=123:Domain=www.example.com" |> display_set_cookie_attributes;;
+Name : SID
+NamePrefix: __Secure-
+Secure : false
- : unit = ()

# Set_cookie.decode "__Host-SID=123" |> display_set_cookie_attributes;;
+Name : SID
+NamePrefix: __Host-
+Secure : false
- : unit = ()
```

## encode

Encode must prefix `__Host-` prefix to `Set-Cookie` name.


```ocaml
# Set_cookie.make ~name_prefix:Cookie_name_prefix.host ~name:"SID" "1234"
  |> Set_cookie.(add secure)
  |> Set_cookie.(add ~v:"/" path)
  |> Set_cookie.encode;;
- : string = "__Host-SID=1234; Path=/; Secure"
```

Domain attribute is present, therefore we fallback to `__Secure-` prefix.

```ocaml
# Set_cookie.make ~name_prefix:Cookie_name_prefix.secure ~name:"SID" "1234"
  |> Set_cookie.(add secure)
  |> Set_cookie.(add ~v:"/" path)
  |> Set_cookie.(add ~v:(Domain_name.of_string_exn "www.example.com") domain)
  |> Set_cookie.encode;;
- : string = "__Secure-SID=1234; Domain=www.example.com; Path=/; Secure"
```

## expire/is_expired

Expire a `Set-Cookie`.

```ocaml
let now = 1666627935.85052109 
let mock_clock = Eio_mock.Clock.make ()
let () = Eio_mock.Clock.set_time mock_clock now
let dt1 = Date.now mock_clock;;
```

```ocaml
# let t0 = 
  Set_cookie.make ~name:"SID" "123"
  |> Set_cookie.(add ~v:dt1 expires);;
val t0 : Set_cookie.t = <abstr>

# Set_cookie.encode t0;; 
- : string = "SID=123; Expires=Mon, 24 Oct 2022 16:12:15 GMT"

# let e0 = Set_cookie.expire t0;;
val e0 : Set_cookie.t = <abstr>

# Set_cookie.encode e0;;
- : string = "SID=123; Max-Age=-1"
```

`is_expired` is `true` for `e0` since `Max-Age <= 0`.

```ocaml
# Set_cookie.is_expired mock_clock e0;;
- : bool = true
```

`is_expired` is `false` if `Max-Age > 0`.

```ocaml
# Set_cookie.make ~name:"SID" "1234"
  |> Set_cookie.(add ~v:1 max_age)
  |> Set_cookie.is_expired mock_clock
- : bool = false
```

`is_expired t0` is `false` since the `Expires` timestamp is equal to clock now value.

```ocaml
# Set_cookie.is_expired mock_clock t0;;
- : bool = false
```

1. Increment the `mock_clock` time by `1.`.
2. `is_expired t0` should be `true`.

```ocaml
# Eio_mock.Clock.set_time mock_clock (now +. 1.);;
+mock time is now 1.66663e+09
- : unit = ()

# Set_cookie.is_expired mock_clock t0;;
- : bool = true
```

## Add and find attributes in Set-Cookie

Expires attribute.

1. Create Date.t value `dt1`.
2. Add `Expires` attribute with `dt1` `t`.
3. Find `Expires` attribute in `t` to `dt2`.
4. `dt1` is equal to `dt2`.

```ocaml
let dt1 = Date.of_float_s 1623940778.27033591 |> Option.get
```

```ocaml
# let t = Set_cookie.(add ~v:dt1 expires t);;
val t : Set_cookie.t = <abstr>

# let dt2 = Set_cookie.(find_opt expires t) |> Option.get;;
val dt2 : Date.t = <abstr>

# Date.encode dt2;;
- : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# Date.equal dt1 dt2;;
- : bool = true
```

Secure attribute.

1. Find `secure` attribute. It is `false`.
2. Add `secure` attribute and find it. It is `true`.

```ocaml
# Set_cookie.(find secure t);;
- : bool = false

# let t = Set_cookie.(add secure t);;
val t : Set_cookie.t = <abstr>

# Set_cookie.(find secure t);;
- : bool = true
```

## decode/encode/compare/equal

Test decoding `Set-Cookie` name, value and attributes. The attribute names are
case in-sensitive.

1. Decode `s` to `t`. Note the parse should be robust against whitespaces.
2. Display name, value, extension.
3. Find `Path` = '/'.
4. Find `Domain` = 'example.com'.
5. Find `Secure` = `true`.
6. Find `HttpOnly` = `true`.
7. Find `Max-Age` = `123`.
7. Find `Expires` = `Thu, 17 Jun 2021 14:39:38 GMT`
7. Find `SameSite` = `Strict`.
8. Encode `t` to `s1`.
9. Decode `s1` to `t1`.
10. Encode `t1` to `s2`.
11. `s1` is equal to `s2`.
12. Compare `t` and `t1` is `0`. 
13. Equal `ta and `t1` is `true`.

```ocaml
let s = "SID=31d4d96e407aad42; Expires=Thu, 17 Jun 2021 14:39:38 GMT; Path=/; Domain=example.com; ASDFas@sadfa\\;secure   ; HttpOnly    ; MaX-age =  123; SameSite=Strict"
```

```ocaml
# let t = Set_cookie.decode s;;
val t : Set_cookie.t = <abstr>

# display_set_cookie_details t;;
+name: SID
+value: '31d4d96e407aad42'
+extension: 'ASDFas@sadfa\'
- : unit = ()

# Set_cookie.(find path t);;
- : string = "/"

# Set_cookie.(find domain t) |> Domain_name.to_string;;
- : string = "example.com"

# Set_cookie.(find secure t);; 
- : bool = true

# Set_cookie.(find http_only t);;
- : bool = true

# Set_cookie.(find max_age t);;
- : int = 123

# Set_cookie.(find expires t) |> Date.encode;;
- : string = "Thu, 17 Jun 2021 14:39:38 GMT"

# Set_cookie.(find same_site t);;
- : Set_cookie.same_site = "Strict"

# let s1 = Set_cookie.encode t;;
val s1 : string =
  "SID=31d4d96e407aad42; Domain=example.com; Expires=Thu, 17 Jun 2021 14:39:38 GMT; Httponly; Max-Age=123; Path=/; Samesite=Strict; Secure"

# let t1 = Set_cookie.(decode s1);;
val t1 : Set_cookie.t = <abstr>

# let s2 = Set_cookie.encode t1;;
val s2 : string =
  "SID=31d4d96e407aad42; Domain=example.com; Expires=Thu, 17 Jun 2021 14:39:38 GMT; Httponly; Max-Age=123; Path=/; Samesite=Strict; Secure"

# s1 = s2;;
- : bool = true

# Set_cookie.compare t t1;; 
- : int = 0

# Set_cookie.equal t t1;;
- : bool = true
```

Decode name/value only.

```ocaml
# let t = Set_cookie.(decode "SID=31d4d96e407aad42");;
val t : Set_cookie.t = <abstr>

# display_set_cookie_details t;;
+name: SID
+value: '31d4d96e407aad42'
- : unit = ()

# Set_cookie.(find http_only t);;
- : bool = false

# Set_cookie.(find_opt http_only t);;
- : bool option = None
```

Empty Set-Cookie value is allowed.

```ocaml
# Set_cookie.decode "SID=";;
- : Set_cookie.t = <abstr>
```

Set-Cookie value can be double quoted. Decoding and encoding such values should preserve double quotes are part of the cookie value, i.e. double quotes are part of the value and aren't stripped away when decoding.

```ocaml
# Set_cookie.decode {|SID="hello-world"|} |> Set_cookie.encode;;
- : string = "SID=\"hello-world\""
```

## remove

Remove name/value attribute.

1. Decode `t` from `s`.
2. Find_opt `Max-Age` is `Some 123`. 
3. Remove `Max-Age`.
2. Find `Max-Age` is `None`. 

```ocaml
# let t = Set_cookie.decode s;;
val t : Set_cookie.t = <abstr>

# Set_cookie.(find_opt max_age t) ;;
- : int option = Some 123

# let t = Set_cookie.(remove max_age t);;
val t : Set_cookie.t = <abstr>

# Set_cookie.(find_opt max_age t);;
- : int option = None
```

Remove bool attribute.

1. Find `Secure` in `t` is `true`.
2. Find_opt `Secure` in `t` is `Some true`.
2. Remove `Secure` from `t`.
3. Find `Secure` in `t` is `false`.
4. Find_opt `Secure` in `t` is `None`.

```ocaml
# Set_cookie.(find secure t);;
- : bool = true

# Set_cookie.(find_opt secure t);;
- : bool option = Some true

# let t = Set_cookie.(remove secure t);;
val t : Set_cookie.t = <abstr>

# Set_cookie.(find secure t);;
- : bool = false

# Set_cookie.(find_opt secure t);;
- : bool option = None
```

## pp

Pretty print.

```ocaml
let t = Set_cookie.decode s2 
```

```ocaml

# Eio.traceln "%a" Set_cookie.pp t;;
+{
+  Name : 'SID' ;
+  Value : '31d4d96e407aad42' ;
+  Domain : 'example.com' ;
+  Expires : 'Thu, 17 Jun 2021 14:39:38 GMT' ;
+  Httponly ;
+  Max-Age : '123' ;
+  Path : '/' ;
+  Samesite : 'Strict' ;
+  Secure ;
+}
- : unit = ()
```

Pretty print name/value only.

```ocaml
let t = Set_cookie.make ~name:"SID" "helloWorld";; 
```

```ocaml
# Eio.traceln "%a" Set_cookie.pp t;; 
+{
+  Name : 'SID' ;
+  Value : 'helloWorld' ;
+}
- : unit = ()
```

