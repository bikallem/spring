open Astring

(* [t] is the node type *)
class type ['repr] t =
  object
    (* Attribute value constructors *)
    method unquoted_attribute_value : string -> 'repr

    method single_quoted_attribute_value : string -> 'repr

    method double_quoted_attribute_value : string -> 'repr

    method code_attribute_value : string -> 'repr

    (* Attribute constructors *)
    method bool_attr : string -> 'repr (* <input disabled> *)

    method attribute : string -> 'repr -> 'repr

    (* <input { } /> *)
    method code_attribute : string -> 'repr

    (* Element constructors *)

    (* method int : int -> 'repr

          method float : float -> 'repr

          method raw_text : string -> 'repr
    *)
    method text : string -> 'repr

    method element : 'repr list -> 'repr t list -> string -> 'repr

    method code_block : string -> 'repr

    method code_element : 'repr t list -> 'repr

    method comment : string -> 'repr
  end

(* Attribute constructors *)

let unquoted_attribute_value code ro = ro#unquoted_attribute_value code

let single_quoted_attribute_value v ro = ro#single_quoted_attribute_value v

let double_quoted_attribute_value v ro = ro#double_quoted_attribute_value v

let code_attribute_value code ro = ro#code_attribute_value code

let bool_attr name ro = ro#bool_attr name

let attribute name value ro =
  let v = value ro in
  ro#attribute name v

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

let element ?(attributes = []) ?(children = []) tag ro =
  let attributes = List.map (fun attr -> attr ro) attributes in
  let children = List.map (fun child -> child ro) children in
  ro#element attributes children tag

let code_block code ro = ro#code_block code

let code_element children ro =
  let children = List.map (fun child -> child ro) children in
  ro#code_element children

let comment txt ro = ro#comment txt

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
    method unquoted_attribute_value code : string = code

    method single_quoted_attribute_value v : string = "'" ^ v ^ "'"

    method double_quoted_attribute_value v : string = "\"" ^ v ^ "\""

    method code_attribute_value code : string = "{" ^ code ^ "}"

    method bool_attr name : string = name

    method attribute name value : string = name ^ "=" ^ value

    method code_attribute code_block : string = "{" ^ code_block ^ "}"

    method text s : string = s

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

    method comment txt : string =
      let b = Buffer.create 10 in
      Buffer.add_string b "<!--";
      Buffer.add_string b txt;
      Buffer.add_string b "-->";
      Buffer.contents b
  end
