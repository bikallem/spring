(** [Content_disposition] implements [Content-Disposition] header as specified
    in https://httpwg.org/specs/rfc6266.html#top *)

type t
(** [t] is the [Content-Disposition] header value. *)

val make : ?params:(string * string) list -> string -> t

val decode : string -> t
(** [decode v] decodes [v] into [t] where [v] holds [Content-Disposition] header
    value in textual format.

    {[
      Content_disposition.decode "formdata; filename=example.html;"
    ]} *)

val encode : t -> string
(** [encode t] encodes [t] into a textual representation of
    [Content-Disposition] header value. *)

val disposition : t -> string
(** [disposition t] returns the disposition value of [t].

    {[
      Content_disposition.decode "formdata; filename=example.html;"
      |> Content_disposition.disposition
    ]}

    returns ["formdata"]. *)

val find_param : t -> string -> string option
(** [find_param t param_name] is [Some param_value] if [param_name] exists in
    [t]. It is [None] otherwise. *)
