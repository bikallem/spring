(** [Content_disposition] implements [Content-Disposition] header as specified
    in https://httpwg.org/specs/rfc6266.html#top *)

(** [t] is the [Content-Disposition] header value. *)
type t

val make : ?params:(string * string) list -> string -> t

(** [decode v] decodes [v] into [t] where [v] holds [Content-Disposition] header
    value in textual format.

    {[
      Content_disposition.decode "formdata; filename=example.html;"
    ]} *)
val decode : string -> t

(** [encode t] encodes [t] into a textual representation of
    [Content-Disposition] header value. *)
val encode : t -> string

(** [disposition t] returns the disposition value of [t].

    {[
      Content_disposition.decode "formdata; filename=example.html;"
      |> Content_disposition.disposition
    ]}

    returns ["formdata"]. *)
val disposition : t -> string

(** [find_param t param_name] is [Some param_value] if [param_name] exists in
    [t]. It is [None] otherwise. *)
val find_param : t -> string -> string option
