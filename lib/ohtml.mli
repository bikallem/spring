type html_writer = Buffer.t -> unit

val escape_html : string -> string
(** [escape_html s] is a XSS attack safe version of HTML text value [s]. *)

val escape_attr : string -> string
(** [escape_attr s] is a XSS attack safe version of HTML attribute value [s]. *)

(** {1 Attribute} *)

type attribute

val attribute : name:string -> value:string -> attribute
(** [attribute ~name ~value] is a html attribute with [name] and [value]. *)

val bool_attribute : string -> attribute
(** [bool_attribute name] is a [name] only attribute, eg. disabled. *)

val null_attribute : attribute
(** [null_attribute] is a no-op attribute. It outpus nothing. *)

val write_attribute : attribute -> html_writer
