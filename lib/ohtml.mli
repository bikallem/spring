type html_writer = Buffer.t -> unit

val escape_html : string -> string
(** [escape_html s] is a XSS attack safe version of string [s]. *)

(** {1 Attribute} *)

val attribute : name:string -> value:string -> html_writer
(** [attribute ~name ~value] writes HTML attribute with [name] and [value]. Both
    [name] and [value] are HTML escaped. *)

(** {1 Element} *)

val text : string -> html_writer
(** [text txt] HTML escapes [txt] and writes [txt]. *)

val raw_text : string -> html_writer
(** [raw_text txt] writes [txt] without HTML escaping. *)

val int : int -> html_writer

(** {1 List} *)

val iter : ('a -> html_writer) -> 'a list -> html_writer
(** [iter f l] writes a list of items in [l], where [f] maps the item to
    [html_writer]. *)
