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
    method attribute : string -> 'repr t -> 'repr

    (* <input { } /> *)
    method code_attribute : string -> 'repr

    (* Element constructors *)

    method text : string -> 'repr
    method element : 'repr t list -> 'repr t list -> string -> 'repr
    method code_block : string -> 'repr
    method code_element : 'repr t list -> 'repr
    method comment : string -> 'repr

    (* Document constructors *)

    method doc : string list -> 'repr t -> 'repr
  end

(* Attribute constructors *)

let unquoted_attribute_value code ro = ro#unquoted_attribute_value code
let single_quoted_attribute_value v ro = ro#single_quoted_attribute_value v
let double_quoted_attribute_value v ro = ro#double_quoted_attribute_value v
let code_attribute_value code ro = ro#code_attribute_value code
let bool_attr name ro = ro#bool_attr name
let attribute name value ro = ro#attribute name value
let code_attribute code_block ro = ro#code_attribute code_block

(* [t] Constructors *)

let escape_html txt =
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
        Buffer.add_string escaped ("&#" ^ string_of_int (Char.code c) ^ ";")
      | c -> Buffer.add_char escaped c)
    txt;
  Buffer.contents escaped

let text txt ro = ro#text txt

let element ?(attributes = []) ?(children = []) tag ro =
  ro#element attributes children tag

let code_block code ro = ro#code_block code
let code_element children ro = ro#code_element children
let comment txt ro = ro#comment txt
let doc pars root_el ro = ro#doc pars root_el

type html_writer = Buffer.t -> unit

let html_text txt : html_writer = fun b -> Buffer.add_string b (escape_html txt)
let raw_text txt : html_writer = fun b -> Buffer.add_string b txt

(* Interpreters *)

(* pretty printer - mostly for parser tests and debugging. *)
class pp =
  let pp_attributes attributes b =
    List.iter
      (fun attr ->
        Buffer.add_char b ' ';
        Buffer.add_string b attr)
      attributes
  in
  let pp_params pars b =
    match pars with
    | [] -> ()
    | _ ->
      Buffer.add_string b "@params";
      List.iter
        (fun p ->
          Buffer.add_char b ' ';
          Buffer.add_string b p)
        pars;
      Buffer.add_char b '\n'
  in
  object (self)
    method unquoted_attribute_value v : string = v
    method single_quoted_attribute_value v : string = "'" ^ v ^ "'"
    method double_quoted_attribute_value v : string = "\"" ^ v ^ "\""
    method code_attribute_value code : string = "{" ^ code ^ "}"
    method bool_attr name : string = name

    method attribute name value : string =
      let v = value self in
      name ^ "=" ^ v

    method code_attribute code_block : string = "{" ^ code_block ^ "}"
    method text s : string = s

    method element attributes children tag =
      let attributes = List.map (fun attr -> attr self) attributes in
      let children = List.map (fun child -> child self) children in
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
      let children = List.map (fun child -> child self) children in
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

    method doc pars root_el : string =
      let el = root_el self in
      let b = Buffer.create 10 in
      pp_params pars b;
      Buffer.add_string b el;
      Buffer.contents b
  end

(* server side renderer - generates OCaml code *)
class ssr (f : string -> unit) (func_name : string) =
  object (self : 'a)
    method unquoted_attribute_value v : unit =
      f "Buffer.add_string b ";
      f v

    method single_quoted_attribute_value v : unit = f @@ "'" ^ v ^ "'"
    method double_quoted_attribute_value v : unit = f @@ "\"" ^ v ^ "\""
    method code_attribute_value code : unit = f @@ code
    method bool_attr name : unit = f name
    method attribute (_name : string) (_value : 'a -> unit) : unit = ()
    (* f name;
       f "=";
       value self *)

    method code_attribute (_code_block : string) : unit =
      () (* "{" ^ code_block ^ "}" *)

    method text txt : unit =
      f @@ "\nBuffer.add_string b ";
      f @@ txt

    method element (attributes : ('a -> unit) list)
        (children : ('a -> unit) list) tag =
      f @@ "\nBuffer.add_string b \"<" ^ tag ^ "\";";
      List.iter (fun a -> a self) attributes;
      f "\nBuffer.add_string b \">\";";
      List.iter (fun child -> child self) children;
      f @@ "\nBuffer.add_string b \"</" ^ tag ^ ">\""

    method code_block (code : string) : unit = f @@ code

    method code_element (children : ('a -> unit) list) : unit =
      f @@ "\n(fun b -> ";
      List.iter (fun child -> child self) children;
      f @@ " ) b;"

    method comment (_txt : string) : unit = ()
    (*
      let b = Buffer.create 10 in
      Buffer.add_string b "<!--";
      Buffer.add_string b txt;
      Buffer.add_string b "-->";
      Buffer.contents b
      *)

    method doc (pars : string list) (root_el : 'a -> unit) : unit =
      f @@ "let " ^ func_name;
      List.iter (fun p -> f @@ " " ^ p) pars;
      f @@ " : Node.html_writer =\nfun b -> ";
      root_el self
  end
