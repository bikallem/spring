type html_writer = Buffer.t -> unit

(*
   HTML Escaping guidance -
   https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
*)

let escape_html txt =
  let escaped = Buffer.create 10 in
  String.iter
    (function
      | '&' -> Buffer.add_string escaped "&amp;"
      | '<' -> Buffer.add_string escaped "&lt;"
      | '>' -> Buffer.add_string escaped "&gt;"
      | c -> Buffer.add_char escaped c)
    txt;
  Buffer.contents escaped

let escape_attr attr_val =
  let escaped = Buffer.create 10 in
  String.iter
    (function
      | '"' -> Buffer.add_string escaped "&quot;"
      | '\'' -> Buffer.add_string escaped "&#x27;"
      | c -> Buffer.add_char escaped c)
    attr_val;
  Buffer.contents escaped

type attribute =
  | Name_val of { name : string; value : string }
  | Bool of string
  | Null

let attribute ~name ~value = Name_val { name; value }
let bool_attribute name = Bool name
let null_attribute = Null

let write_attribute attr : html_writer =
 fun b ->
  match attr with
  | Name_val { name; value } ->
    Buffer.add_string b (escape_attr name);
    Buffer.add_string b {|="|};
    Buffer.add_string b (escape_attr value);
    Buffer.add_string b {|"|}
  | Bool name -> Buffer.add_string b (escape_attr name)
  | Null -> ()
