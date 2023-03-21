type html_writer = Buffer.t -> unit

(** {1 Attribute} *)

val attribute : name:string -> value:string -> html_writer
(** [attribute ~name ~value] writes HTML attribute with [name] and [value]. Both
    [name] and [value] are HTML escaped. *)

(** {1 Element} *)

val text : string -> html_writer
(** [text txt] HTML escapes [txt] and writes [txt]. *)

val raw_text : string -> html_writer
(** [raw_text txt] writes [txt] without HTML escaping. *)

(** {1 List} *)

val iter : ('a -> html_writer) -> 'a list -> html_writer
