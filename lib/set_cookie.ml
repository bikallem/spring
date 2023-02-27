type t =
  { name : string
  ; value : string
  ; expires : Ptime.t option
  ; max_age : int option
  ; domain : [ `raw ] Domain_name.t option
  ; path : string option
  ; secure : bool
  ; http_only : bool
  ; extensions : string list
  }

type name_value = string * string

let make ?expires ?max_age ?domain ?path ?(secure = true) ?(http_only = true)
    ?(extensions = []) (name, value) =
  { name; value; expires; max_age; domain; path; secure; http_only; extensions }

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
  | c -> failwith @@ "eq: expected '=', got '" ^ Char.escaped c ^ "'"

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
  let rec aux () =
    if s.pos < String.length s.i then
      match String.get s.i s.pos with
      | ';' ->
        accept s 1;
        space s;
        let attr_nm =
          String.take
            ~sat:(function
              | ';' | '=' -> false
              | _ -> true)
            (String.with_range ~first:s.pos s.i)
        in
        accept s (String.length attr_nm);
        let attr_val =
          match attr_nm with
          | "Expires" | "Max-Age" | "Domain" | "Path" ->
            eq s;
            av_value s
          | _ -> ""
        in
        (attr_nm, attr_val) :: aux ()
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
  let t =
    { name
    ; value
    ; expires = None
    ; max_age = None
    ; domain = None
    ; path = None
    ; secure = false
    ; http_only = false
    ; extensions = []
    }
  in
  List.fold_left
    (fun t (k, v) ->
      match k with
      | "Expires" -> (
        try
          let v = Date.decode v in
          { t with expires = Some v }
        with e -> failwith @@ "expires: " ^ Printexc.to_string e)
      | "Max-Age" -> (
        try
          let v = int_of_string v in
          { t with max_age = Some v }
        with _ -> failwith "max-age: invalid max-age value")
      | "Domain" -> (
        match Domain_name.of_string v with
        | Ok d -> { t with domain = Some d }
        | Error _ ->
          failwith @@ "domain: invalid domain attribute value '" ^ v ^ "'")
      | "Path" ->
        if is_av_octet v then { t with path = Some v }
        else failwith "path: invalid path value"
      | "Secure" -> { t with secure = true }
      | "HttpOnly" -> { t with http_only = true }
      | av -> { t with extensions = av :: t.extensions })
    t attributes

let name t = t.name

let value t = t.value

let expires t = t.expires

let max_age t = t.max_age

let domain t = t.domain

let path t = t.path

let secure t = t.secure

let http_only t = t.http_only

let extensions t = t.extensions

let expire t =
  { t with
    value = ""
  ; expires = None
  ; max_age = Some (-1)
  ; domain = None
  ; path = None
  ; secure = false
  ; http_only = false
  ; extensions = []
  }

open Easy_format
open Option.Syntax

let field lbl v =
  let lbl = Atom (lbl ^ ": ", atom) in
  let v = Atom (v, atom) in
  Label ((lbl, label), v)

let pp fmt t =
  let param =
    { list with
      stick_to_label = false
    ; align_closing = true
    ; space_after_separator = true
    ; wrap_body = `Force_breaks
    }
  in
  let fields =
    [ ("Name", Some t.name)
    ; ("Value", Some t.value)
    ; ( "Expires"
      , let+ v = t.expires in
        Date.encode v )
    ; ( "Max-Age"
      , let+ v = t.max_age in
        string_of_int v )
    ; ( "Domain"
      , let+ v = t.domain in
        Domain_name.to_string v )
    ; ("Path", t.path)
    ; ("Secure", if t.secure then Some "" else None)
    ; ("HttpOnly", if t.http_only then Some "" else None)
    ]
  in
  let fields =
    List.fold_right
      (fun (k, v) acc ->
        match v with
        | Some "" -> Atom (k, atom) :: acc
        | Some v -> field k v :: acc
        | None -> acc)
      fields []
  in
  let fields =
    fields @ List.map (fun v -> Atom (v, atom)) (List.rev t.extensions)
  in
  Easy_format.Pretty.to_formatter fmt @@ List (("{", ";", "}", param), fields)
