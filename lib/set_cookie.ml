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
  ; same_site : same_site option
  }

and same_site = string

type name_value = string * string

let strict = "Strict"
let lax = "Lax"

let make ?expires ?max_age ?domain ?path ?(secure = true) ?(http_only = true)
    ?(extensions = []) ?same_site (name, value) =
  { name
  ; value
  ; expires
  ; max_age
  ; domain
  ; path
  ; secure
  ; http_only
  ; extensions
  ; same_site
  }

include Cookie_parser

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
          |> String.Ascii.lowercase
        in
        accept s (String.length attr_nm);
        let attr_val =
          match attr_nm with
          | "expires" | "max-age" | "domain" | "path" | "samesite" ->
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
    ; same_site = None
    }
  in
  List.fold_left
    (fun t (k, v) ->
      match k with
      | "expires" -> (
        try
          let v = Date.decode v in
          { t with expires = Some v }
        with e -> failwith @@ "expires: " ^ Printexc.to_string e)
      | "max-age" -> (
        try
          let v = int_of_string v in
          { t with max_age = Some v }
        with _ -> failwith "max-age: invalid max-age value")
      | "domain" -> (
        match Domain_name.of_string v with
        | Ok d -> { t with domain = Some d }
        | Error _ ->
          failwith @@ "domain: invalid domain attribute value '" ^ v ^ "'")
      | "path" ->
        if is_av_octet v then { t with path = Some v }
        else failwith "path: invalid path value"
      | "samesite" -> (
        match v with
        | "Strict" | "Lax" -> { t with same_site = Some v }
        | _ -> failwith "same_site: invalid same-site value")
      | "secure" -> { t with secure = true }
      | "httponly" -> { t with http_only = true }
      | av -> { t with extensions = av :: t.extensions })
    t attributes

let encode t =
  let module O = Option in
  let b = Buffer.create 10 in
  Buffer.add_string b t.name;
  Buffer.add_char b '=';
  Buffer.add_string b t.value;
  O.iter (fun path -> Buffer.add_string b @@ "; Path=" ^ path) t.path;
  O.iter
    (fun domain ->
      Buffer.add_string b @@ "; Domain=" ^ Domain_name.to_string domain)
    t.domain;
  O.iter
    (fun expires -> Buffer.add_string b @@ "; Expires=" ^ Date.encode expires)
    t.expires;
  O.iter
    (fun max_age -> Buffer.add_string b @@ "; Max-Age=" ^ string_of_int max_age)
    t.max_age;
  O.iter
    (fun same_site -> Buffer.add_string b @@ "; SameSite=" ^ same_site)
    t.same_site;
  if t.secure then Buffer.add_string b "; Secure";
  if t.http_only then Buffer.add_string b "; HttpOnly";

  Buffer.contents b

let name t = t.name
let value t = t.value
let expires t = t.expires
let max_age t = t.max_age
let domain t = t.domain
let path t = t.path
let secure t = t.secure
let http_only t = t.http_only
let extensions t = t.extensions
let same_site t = t.same_site

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
  ; same_site = None
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
    ; ("SameSite", t.same_site)
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
