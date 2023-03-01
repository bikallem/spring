open Astring

type attribute = string * string

(* [t] is the node type *)
class type ['repr] t =
  object
    (* method int : int -> 'repr

          method float : float -> 'repr

          method raw_text : string -> 'repr
       method void : attribute list -> string -> 'repr
    *)
    method text : string -> 'repr

    method element : 'repr t list -> string -> 'repr
  end

(* Constructors *)
(* let int n ro = ro#int n *)

(* let float x ro = ro#float x *)

let text txt ro =
  let escaped = Buffer.create 10 in
  String.iter
    (function
      | '&' -> Buffer.add_string escaped "&amp;"
      | '<' -> Buffer.add_string escaped "&lt;"
      | '>' -> Buffer.add_string escaped "&gt;"
      | '"' -> Buffer.add_string escaped "&quot;"
      | '\039' -> Buffer.add_string escaped "&#x27;"
      | '\047' -> Buffer.add_string escaped "&#x2F;"
      | ('\x00' .. '\x1F' as c) | ('\x7F' as c) ->
        Buffer.add_string escaped ("&#" ^ string_of_int (Char.to_int c) ^ ";")
      | c -> Buffer.add_char escaped c)
    txt;
  let txt = Buffer.contents escaped in
  ro#text txt

(* let raw_text txt ro = ro#text txt *)

(* let void ?(attributes = []) name ro = ro#void ~attributes name *)

let element ?(children = []) name ro =
  let children = List.map (fun child -> child ro) children in
  ro#element children name

(* interpreters *)

class html =
  object
    method text s : string = s

    method element children name =
      let b = Buffer.create 10 in
      Buffer.add_string b ("<" ^ name ^ ">");
      List.iter (Buffer.add_string b) children;
      Buffer.add_string b ("<" ^ name ^ "/>");
      Buffer.contents b
  end

(* parser input *)

let nul = '\000'

class virtual input =
  object (self)
    val mutable line = 1

    val mutable col = 0

    val mutable c = nul

    val buf = Buffer.create 10

    method line = line

    method col = col

    method c = c

    method buf = buf

    method add = Buffer.add_char buf c

    method next =
      let c' = self#char in
      match c' with
      | '\n' ->
        col <- 1;
        line <- line + 1;
        c <- c'
      | _ ->
        col <- col + 1;
        c <- c'

    method next_char =
      self#next;
      self#c

    method virtual char : char
  end

let string_input s =
  let len = String.length s in
  let pos = ref (-1) in
  object
    inherit input

    method char =
      incr pos;
      if !pos = len then (
        c <- nul;
        raise End_of_file)
      else String.get s !pos
  end

let channel_input in_channel =
  object
    inherit input

    method char = input_char in_channel
  end

let err lbl msg (i : #input) =
  failwith
    (lbl ^ "(" ^ string_of_int i#line ^ "," ^ string_of_int i#col ^ ") : " ^ msg)

let clear (i : #input) = Buffer.clear i#buf

let is_alpha = function
  | 'a' .. 'z' | 'A' .. 'Z' -> true
  | _ -> false

let is_digit = function
  | '0' .. '9' -> true
  | _ -> false

let is_alpha_num = function
  | c -> is_alpha c || is_digit c

let rec p_skip_ws (i : #input) =
  match i#next_char with
  | '\t' | ' ' | '\n' | '\r' -> p_skip_ws i
  | _ -> ()

let p_tag i =
  let rec aux () =
    match i#next_char with
    | c when is_alpha_num c ->
      i#add;
      aux ()
    | '_' | '\'' | '.' ->
      i#add;
      aux ()
    | _ ->
      let tag = Buffer.contents i#buf in
      clear i;
      tag
  in
  match i#next_char with
  | c when is_alpha c || c = '_' ->
    i#add;
    aux ()
  | _ ->
    err "start_tag" "tag name must start with an alphabet or '_' character" i

let start_tag (i : #input) =
  p_skip_ws i;
  match i#c with
  | '<' -> p_tag i
  | _ -> err "start_tag" "start tag must start with '<'" i
