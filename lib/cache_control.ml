module Directive = struct
  type 'a decode = string -> 'a

  type 'a encode = 'a -> string

  type name = string

  type 'a name_val =
    { name : name
    ; decode : 'a decode
    ; encode : 'a encode
    }

  type 'a t =
    | Bool : name -> bool t
    | Name_val : 'a name_val -> 'a t

  type bool' = bool t

  let name : type a. a t -> string = function
    | Bool name -> name
    | Name_val { name; _ } -> name

  let is_bool : type a. a t -> bool = function
    | Bool _ -> true
    | Name_val _ -> false

  let decode : type a. a t -> a decode option = function
    | Bool _ -> None
    | Name_val { decode; _ } -> Some decode

  let encode : type a. a t -> a encode option = function
    | Bool _ -> None
    | Name_val { encode; _ } -> Some encode
end

type delta_seconds = int

let delta_seconds_directive name =
  let decode s =
    let buf_read = Buf_read.of_string s in
    Buf_read.delta_seconds buf_read
  in
  let encode = string_of_int in
  Directive.Name_val { Directive.name; decode; encode }

let max_age = delta_seconds_directive "max-age"

let max_stale = delta_seconds_directive "max-stale"

let no_cache = Directive.Bool "no-cache"

type t = (string * string option) list

let empty = []

let add : type a. ?v:a -> a Directive.t -> t -> t =
 fun ?v d t ->
  let v =
    match d with
    | Bool _ -> None
    | Name_val { encode; _ } -> (
      match v with
      | Some v -> Some (encode v)
      | None ->
        invalid_arg "[v] is [None] but is required for non bool directives")
  in
  (Directive.name d, v) :: t

let decode_value : type a. a Directive.t -> string option -> a option =
 fun d v ->
  match d with
  | Directive.Bool _ -> Some true
  | Name_val { decode; _ } -> Option.map decode v

let find_opt : type a. a Directive.t -> t -> a option =
 fun d t ->
  let find_name = Directive.name d in
  let rec loop = function
    | [] -> None
    | (directive_name, v) :: l ->
      if String.equal directive_name find_name then decode_value d v else loop l
  in
  loop t

let coerce_bool_directive : type a. a Directive.t -> a = function
  | Bool _ -> false
  | _ -> raise Not_found

let find : type a. a Directive.t -> t -> a =
 fun d t ->
  match find_opt d t with
  | Some v -> v
  | None -> coerce_bool_directive d

let decode_cache_directive buf_read =
  let name = Buf_read.token buf_read in
  match Buf_read.peek_char buf_read with
  | Some '=' ->
    Buf_read.char '=' buf_read;
    (* -- token / quoted_string -- *)
    let v =
      match Buf_read.peek_char buf_read with
      | Some '"' -> "\"" ^ Buf_read.quoted_string buf_read ^ "\""
      | Some _ -> Buf_read.token buf_read
      | None -> failwith "[cache_directive] invalid cache-directive value"
    in
    (name, Some v)
  | Some _ | None -> (name, None)

let decode s =
  let buf_read = Buf_read.of_string s in
  Buf_read.list1 decode_cache_directive buf_read

let encode_cache_directive buf (name, v) =
  Buffer.add_string buf name;
  match v with
  | Some v ->
    Buffer.add_char buf '=';
    Buffer.add_string buf v
  | None -> ()

let encode = function
  | [] -> ""
  | v :: t ->
    let buf = Buffer.create 10 in
    encode_cache_directive buf v;
    List.iter
      (fun v ->
        Buffer.add_string buf ", ";
        encode_cache_directive buf v)
      t;
    Buffer.contents buf
