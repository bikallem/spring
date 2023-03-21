type html_writer = Buffer.t -> unit

(** {1 Attribute} *)

val attribute : name:string -> value:string -> html_writer
(** [attribute ~name ~value] writes HTML attribute with [name] and [value]. Both
    [name] and [value] are HTML escaped. *)

(** {1 Element} *)

val html_text : string -> html_writer
(** [html_text txt] HTML escapes [txt] and writes [txt]. *)

val raw_text : string -> html_writer
(** [raw_text txt] writes [txt] without HTML escaping. *)
