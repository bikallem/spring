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
