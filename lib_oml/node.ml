open Astring

(* [t] is the node type *)
class type ['repr] t =
  object
    method bool_attr : string -> 'repr (* <input disabled> *)

    method attribute : string -> string -> 'repr

    (* <input { } /> *)
    method code_attribute : string -> 'repr

    (* method int : int -> 'repr

          method float : float -> 'repr

          method raw_text : string -> 'repr
    *)
    method text : string -> 'repr

    method void : 'repr list -> string -> 'repr

    method element : 'repr list -> 'repr t list -> string -> 'repr

    method code_block : string -> 'repr

    method code_element : 'repr t list -> 'repr
  end

(* Attribute constructors *)

let bool_attr name ro = ro#bool_attr name

let attribute name value ro = ro#attribute name value

let code_attribute code_block ro = ro#code_attribute code_block

(* [t] Constructors *)

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

let void ?(attributes = []) tag ro =
  let attributes = List.map (fun attr -> attr ro) attributes in
  ro#void attributes tag

let element ?(attributes = []) ?(children = []) tag ro =
  let attributes = List.map (fun attr -> attr ro) attributes in
  let children = List.map (fun child -> child ro) children in
  ro#element attributes children tag

let code_block code ro = ro#code_block code

let code_element children ro =
  let children = List.map (fun child -> child ro) children in
  ro#code_element children

(* interpreters *)

class pp =
  let pp_attributes attributes b =
    List.iter
      (fun attr ->
        Buffer.add_char b ' ';
        Buffer.add_string b attr)
      attributes
  in
  object
    method bool_attr name : string = name

    method attribute name value : string = name ^ "='" ^ value ^ "'"

    method code_attribute code_block : string = "{" ^ code_block ^ "}"

    method text s : string = s

    method void attributes tag : string =
      let b = Buffer.create 10 in
      Buffer.add_char b '<';
      Buffer.add_string b tag;
      pp_attributes attributes b;
      Buffer.add_string b "/>";
      Buffer.contents b

    method element attributes children tag =
      let b = Buffer.create 10 in
      Buffer.add_char b '<';
      Buffer.add_string b tag;
      pp_attributes attributes b;
      Buffer.add_char b '>';
      List.iter (Buffer.add_string b) children;
      Buffer.add_string b ("</" ^ tag ^ ">");
      Buffer.contents b

    method code_block code : string = code

    method code_element children =
      let b = Buffer.create 10 in
      Buffer.add_char b '{';
      List.iter (Buffer.add_string b) children;
      Buffer.add_char b '}';
      Buffer.contents b
  end
