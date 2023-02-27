type t =
  { name : string
  ; value : string
  ; expires : Ptime.t option
  }

type state =
  { i : string
  ; mutable pos : int
  }

let accept s n = s.pos <- s.pos + n

let _av_octet s =
  let rec aux b =
    match String.get s.i s.pos with
    | ';' | '\x00' .. '\x1F' | '\x7F' -> Buffer.contents b
    | c ->
      accept s 1;
      Buffer.add_char b c;
      aux b
  in
  aux (Buffer.create 5)

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

let attributes = [ "Expires" ] |> List.map (fun v -> (v, String.length v))

let space s =
  match String.get s.i s.pos with
  | ' ' -> accept s 1
  | x -> failwith @@ "space: expected ' '(space), got '" ^ Char.escaped x ^ "'"

let cookie_attributes s =
  let rec aux () =
    if s.pos < String.length s.i then
      match String.get s.i s.pos with
      | ';' -> (
        accept s 1;
        space s;
        match
          List.find_opt
            (fun (av_name, len) ->
              let v = String.with_range ~first:s.pos ~len:(len + 1) s.i in
              let av_name = av_name ^ "=" in
              String.equal v av_name)
            attributes
        with
        | Some (av_name, len) ->
          accept s (len + 1);

          let av_value = av_value s in
          (av_name, av_value) :: aux ()
        | None -> failwith "cookie_av: expected cookie-av")
      | _ -> []
    else []
  in
  aux ()

(* eg . Set-Cookie: lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT *)
let decode v =
  let s = { i = v; pos = 0 } in
  let name = token s in
  eq s;
  let value = cookie_value s in
  let attributes = cookie_attributes s in
  let expires = List.assoc_opt "Expires" attributes |> Option.map Date.decode in
  { name; value; expires }

let name t = t.name

let value t = t.value

let expires t = t.expires
