type html_writer = Buffer.t -> unit

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

let attribute ~name ~value : html_writer =
 fun b ->
  Buffer.add_string b (escape_html name);
  Buffer.add_string b {|="|};
  Buffer.add_string b (escape_html value);
  Buffer.add_string b {|"|}

let text txt : html_writer = fun b -> Buffer.add_string b (escape_html txt)
let raw_text txt : html_writer = fun b -> Buffer.add_string b txt
let int i : html_writer = fun b -> Buffer.add_string b (string_of_int i)

(* list *)

let iter f l : html_writer = fun b -> List.iter (fun x -> f x b) l
