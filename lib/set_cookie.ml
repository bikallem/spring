type t =
  { name : string
  ; value : string
  ; expires : Ptime.t option
  ; max_age : int option
  ; domain : [ `raw ] Domain_name.t option
  ; path : string option
  ; secure : bool
  }

type state =
  { i : string
  ; mutable pos : int
  }

let accept s n = s.pos <- s.pos + n

let token s =
  let rec aux b =
    match String.get s.i s.pos with
    | ( '0' .. '9'
      | 'a' .. 'z'
      | 'A' .. 'Z'
      | '!'
      | '#'
      | '$'
      | '%'
      | '&'
      | '\''
      | '*'
      | '+'
      | '-'
      | '.'
      | '^'
      | '_'
      | '`'
      | '|'
      | '~' ) as c ->
      accept s 1;
      Buffer.add_char b c;
      aux b
    | _ -> Buffer.contents b
  in
  aux (Buffer.create 5)

(* chomp '=' *)
let eq s =
  match String.get s.i s.pos with
  | '=' -> accept s 1
  | c -> failwith @@ "ch_eq: expected '=', got '" ^ Char.escaped c ^ "'"

let cookie_octet s =
  let rec aux b =
    match String.get s.i s.pos with
    | ( '\x21'
      | '\x23' .. '\x2B'
      | '\x2D' .. '\x3A'
      | '\x3C' .. '\x5B'
      | '\x5D' .. '\x7E' ) as c ->
      accept s 1;
      Buffer.add_char b c;
      aux b
    | _ -> Buffer.contents b
  in
  aux (Buffer.create 5)

let cookie_value s =
  match String.get s.i s.pos with
  | '"' -> (
    accept s 1;
    let v = cookie_octet s in
    match String.get s.i s.pos with
    | '"' ->
      accept s 1;
      v
    | c -> failwith "cookie_value: expected '\"', got '" ^ Char.escaped c ^ "'")
  | _ -> cookie_octet s

let av_value s =
  let v =
    String.take
      ~sat:(function
        | ';' -> false
        | _ -> true)
      (String.with_range ~first:s.pos s.i)
  in
  let len = String.length v in
  if len = 0 then failwith "av_value: attribute value missing" else accept s len;
  v

let space s =
  match String.get s.i s.pos with
  | ' ' -> accept s 1
  | x -> failwith @@ "space: expected ' '(space), got '" ^ Char.escaped x ^ "'"

let cookie_attributes s =
  let attributes =
    [ ("Expires", true)
    ; ("Max-Age", true)
    ; ("Domain", true)
    ; ("Path", true)
    ; ("Secure", false)
    ]
  in
  let rec aux () =
    if s.pos < String.length s.i then
      match String.get s.i s.pos with
      | ';' -> (
        accept s 1;
        space s;
        match
          List.find_opt
            (fun (av_name, has_attr_val) ->
              let av_name = if has_attr_val then av_name ^ "=" else av_name in
              let len = String.length av_name in
              let v = String.with_range ~first:s.pos ~len s.i in
              String.equal v av_name)
            attributes
        with
        | Some (av_name, has_attr_val) ->
          let len = String.length av_name in
          let len = if has_attr_val then len + 1 else len in
          accept s len;
          let av_value = if has_attr_val then av_value s else "" in
          (av_name, av_value) :: aux ()
        | None -> failwith "cookie_av: expected cookie-attribute")
      | _ -> []
    else []
  in
  aux ()

let is_av_octet v =
  String.for_all
    (function
      | '\x20' .. '\x3A' | '\x3C' .. '\x7E' -> true
      | _ -> false)
    v

(* eg . Set-Cookie: lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT *)
let decode v =
  let s = { i = v; pos = 0 } in
  let name = token s in
  eq s;
  let value = cookie_value s in
  let attributes = cookie_attributes s in
  let expires = List.assoc_opt "Expires" attributes |> Option.map Date.decode in
  let max_age =
    List.assoc_opt "Max-Age" attributes
    |> Option.map (fun v ->
           try int_of_string v
           with _ -> failwith "max-age: invalid max-age value")
  in
  let domain =
    let o = List.assoc_opt "Domain" attributes in
    Option.bind o (fun v ->
        match Domain_name.of_string v with
        | Ok d -> Some d
        | Error _ ->
          failwith @@ "domain: invalid domain attribute value '" ^ v ^ "'")
  in
  let path =
    List.assoc_opt "Path" attributes
    |> Option.map (fun v ->
           if is_av_octet v then v else failwith "path: invalid path value")
  in
  let secure =
    match List.assoc_opt "Secure" attributes with
    | Some "" -> true
    | Some _ | None -> false
  in
  { name; value; expires; max_age; domain; path; secure }

let name t = t.name

let value t = t.value

let expires t = t.expires

let max_age t = t.max_age

let domain t = t.domain

let path t = t.path

let secure t = t.secure
