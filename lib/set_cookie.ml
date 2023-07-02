type t =
  { name : string
  ; value : string
  ; expires : Date.t option
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

let make
    ?expires
    ?max_age
    ?domain
    ?path
    ?(secure = true)
    ?(http_only = true)
    ?(extensions = [])
    ?same_site
    (name, value) =
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

let av_value r =
  Buf_read.take_while
    (function
      | ';' -> false
      | _ -> true)
    r

let cookie_attributes r =
  let rec aux () =
    let c = Buf_read.peek_char r in
    match c with
    | Some ';' ->
      Buf_read.char ';' r;
      Buf_read.space r;
      let attr_nm =
        Buf_read.take_while
          (function
            | ';' | '=' -> false
            | _ -> true)
          r
        |> String.Ascii.lowercase
      in
      let attr_val =
        match attr_nm with
        | "expires" | "max-age" | "domain" | "path" | "samesite" ->
          Buf_read.char '=' r;
          av_value r
        | _ -> ""
      in
      (attr_nm, attr_val) :: aux ()
    | _ -> []
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
  let r = Buf_read.of_string v in
  let name, value = Buf_read.cookie_pair r in
  let attributes = cookie_attributes r in
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

let pp fmt t =
  let fields =
    Fmt.(
      record ~sep:semi
        [ Fmt.field "Name" (fun t -> t.name) Fmt.string
        ; Fmt.field "Value" (fun t -> t.value) Fmt.string
        ; Fmt.field "Expires" (fun t -> t.expires) Fmt.(option Date.pp)
        ; Fmt.field "Max-Age" (fun t -> t.max_age) Fmt.(option int)
        ; Fmt.field "Domain" (fun t -> t.domain) Fmt.(option Domain_name.pp)
        ; Fmt.field "Path" (fun t -> t.path) Fmt.(option string)
        ; Fmt.field "SameSite" (fun t -> t.same_site) Fmt.(option string)
        ; Fmt.field "Secure" (fun t -> t.secure) Fmt.bool
        ; Fmt.field "HttpOnly" (fun t -> t.http_only) Fmt.bool
        ])
  in
  let open_bracket =
    Fmt.(vbox ~indent:2 @@ (const char '{' ++ cut ++ fields))
  in
  Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt t
