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

(* +-- New --+ *)

(* +-- Set-Cookie Attributes --+ *)
module New = struct
  module Attribute = struct
    type name = string

    type 'a name_val =
      { name : name
      ; decode : string -> 'a
      ; encode : 'a -> string
      }

    type 'a t =
      | Bool : name -> bool t
      | Name_val : 'a name_val -> 'a t

    let lname = String.Ascii.lowercase

    let make_bool name =
      let name = lname name in
      Bool name

    let make_name_val name decode encode =
      Name_val { name = lname name; decode; encode }

    let name : type a. a t -> string = function
      | Bool name -> name
      | Name_val { name; _ } -> name

    let is_bool (type a) (t : a t) =
      match t with
      | Bool _ -> true
      | Name_val _ -> false
  end

  let expires = Attribute.make_name_val "Expires" Date.decode Date.encode

  let max_age = Attribute.make_name_val "Max-Age" int_of_string string_of_int

  let path = Attribute.make_name_val "Path" Fun.id Fun.id

  let domain =
    Attribute.make_name_val "Domain" Domain_name.of_string_exn
      Domain_name.to_string

  let secure = Attribute.make_bool "Secure"

  let http_only = Attribute.make_bool "HttpOnly"

  type same_site = string

  let strict = "Strict"

  let lax = "Lax"

  let same_site =
    Attribute.make_name_val "SameSite"
      (function
        | "Strict" -> strict
        | "Lax" -> lax
        | v -> Fmt.failwith "%s is not a valid SameSite attribute value" v)
      Fun.id

  (* +-- Set-Cookie --+ *)

  module Map = Map.Make (String)

  type t =
    { name : string
    ; value : string
    ; attributes : string option Map.t
    ; extension : string option
    }

  let make ?extension ~name value =
    if String.is_empty name then invalid_arg "[name] is empty"
    else { name; value; attributes = Map.empty; extension }

  let name t = t.name

  let value t = t.value

  let extension t = t.extension

  let add_attribute (type a) ?(v : a option) (attr : a Attribute.t) attributes =
    let v =
      match attr with
      | Bool _ -> None
      | Name_val { encode; _ } -> (
        match v with
        | Some v -> Some (encode v)
        | None ->
          invalid_arg "[v] is [None] but is required for non bool attribute")
    in
    let name = Attribute.name attr in
    Map.add name v attributes

  let expire t =
    let attributes = add_attribute ~v:(-1) max_age Map.empty in
    { t with extension = None; attributes }

  let add ?v attr t =
    let attributes = add_attribute ?v attr t.attributes in
    { t with attributes }

  let find : type a. a Attribute.t -> t -> a =
   fun attr t ->
    let attr_name = Attribute.name attr in
    match (Map.find_opt attr_name t.attributes, attr) with
    | Some _, Attribute.Bool _ -> true
    | None, Bool _ -> false
    | Some v, Name_val { decode; _ } -> decode @@ Option.get v
    | None, Name_val _ -> raise Not_found

  let find_opt : type a. a Attribute.t -> t -> a option =
   fun attr t ->
    let attr_name = Attribute.name attr in
    match (Map.find_opt attr_name t.attributes, attr) with
    | Some _, Attribute.Bool _ -> Some true
    | Some (Some v), Name_val { decode; _ } -> (
      match decode v with
      | v -> Some v
      | exception _ -> None)
    | Some None, _ | None, _ -> None

  let is_max_age_expired t =
    match find_opt max_age t with
    | Some v -> v <= 0
    | None -> false

  let is_expires_expired clock t =
    match find_opt expires t with
    | Some date ->
      let now = Date.now clock in
      Date.is_earlier ~than:now date
    | None -> false

  let is_expired clock t = is_max_age_expired t || is_expires_expired clock t

  let remove : type a. a Attribute.t -> t -> t =
   fun attr t ->
    let attr_name = Attribute.name attr in
    let attributes = Map.remove attr_name t.attributes in
    { t with attributes }

  let compare t0 t1 =
    let cmp = String.compare t0.name t1.name in
    if cmp = 0 then
      let cmp = String.compare t0.value t1.value in
      if cmp = 0 then
        Map.compare (Option.compare String.compare) t0.attributes t1.attributes
      else cmp
    else cmp

  let equal t0 t1 = compare t0 t1 = 0

  let av_octet buf_read =
    Buf_read.take_while
      (function
        | '\x20' .. '\x3A' | '\x3C' .. '\x7E' -> true
        | _ -> false)
      buf_read

  let attribute_names =
    [ Attribute.name expires
    ; "max-age"
    ; "domain"
    ; "path"
    ; "secure"
    ; "httponly"
    ; "samesite"
    ]

  (* split tokens at ';' *)
  let attr_tokens buf_read =
    let extension = ref None in
    let rec loop buf_read m =
      Buf_read.ows buf_read;
      match Buf_read.peek_char buf_read with
      | Some ';' ->
        Buf_read.char ';' buf_read;
        Buf_read.ows buf_read;
        let nm =
          Buf_read.take_while
            (function
              | 'a' .. 'z' | 'A' .. 'Z' -> true
              | '-' -> true
              | _ -> false)
            buf_read
        in
        if List.mem (String.Ascii.lowercase nm) attribute_names then (
          Buf_read.ows buf_read;
          let nm = String.Ascii.lowercase nm in
          match Buf_read.peek_char buf_read with
          | Some '=' ->
            Buf_read.char '=' buf_read;
            Buf_read.ows buf_read;
            let v : string = av_octet buf_read in
            let m = Map.add nm (Some v) m in
            loop buf_read m
          | Some ';' | None ->
            let m = Map.add nm None m in
            loop buf_read m
          | Some c -> Fmt.failwith "expected ';' or '=' but got %c" c)
        else
          let v = av_octet buf_read in
          extension := Some (nm ^ v);
          loop buf_read m
      | Some _ | None -> m
    in
    let attrs = loop buf_read Map.empty in
    (!extension, attrs)

  let host_prefix = "__Host-"

  let secure_prefix = "__Secure-"

  let decode ?(remove_name_prefix = true) s =
    let buf_read = Buf_read.of_string s in
    let name, value = Buf_read.cookie_pair buf_read in
    let name =
      if remove_name_prefix then
        if String.is_prefix ~affix:host_prefix name then
          String.with_range ~first:(String.length host_prefix) name
        else if String.is_prefix ~affix:secure_prefix name then
          String.with_range ~first:(String.length secure_prefix) name
        else name
      else name
    in
    let extension, attributes = attr_tokens buf_read in
    { name; value; extension; attributes }

  let canonical_attribute_name s =
    String.cuts ~sep:"-" s
    |> List.map (fun s -> String.(Ascii.(lowercase s |> capitalize)))
    |> String.concat ~sep:"-"

  let encode ?(prefix_name = true) t =
    let b = Buffer.create 10 in
    let name = t.name in
    let name =
      if prefix_name then
        let secure = find secure t in
        if secure then
          let domain = find_opt domain t in
          let path = find_opt path t in
          match (domain, path) with
          | None, Some "/" -> host_prefix ^ name
          | _, _ -> secure_prefix ^ name
        else name
      else name
    in
    Buffer.add_string b name;
    Buffer.add_char b '=';
    Buffer.add_string b t.value;
    Map.iter
      (fun name v ->
        let name = canonical_attribute_name name in
        match v with
        | Some v ->
          Buffer.add_string b "; ";
          Buffer.add_string b name;
          Buffer.add_char b '=';
          Buffer.add_string b v
        | None ->
          Buffer.add_string b "; ";
          Buffer.add_string b name)
      t.attributes;
    Buffer.contents b

  (* +-- Pretty Printing --+ *)

  let pp_field ?v lbl =
    Fmt.(
      const string lbl
      ++
      match v with
      | Some v -> const string " : '" ++ const string v ++ const string "\' ;"
      | None -> const string " ;")

  let pp fmt t =
    let name = pp_field ~v:t.name "Name" in
    let value = Fmt.(cut ++ pp_field ~v:t.value "Value") in
    let attributes =
      Map.fold
        (fun name v acc ->
          let name = canonical_attribute_name name in
          Fmt.(acc ++ cut ++ pp_field ?v name))
        t.attributes Fmt.nop
    in
    let open_bracket =
      Fmt.(
        vbox ~indent:2 @@ (const char '{' ++ cut ++ name ++ value ++ attributes))
    in
    Fmt.(vbox @@ (open_bracket ++ cut ++ const char '}')) fmt t
end
