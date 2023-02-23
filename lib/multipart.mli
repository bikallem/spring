(** [Multipart] implements HTTP MIME multipart parsing as defined in
    {{:https://tools.ietf.org/html/rfc7578} RFC 7578}. *)

type t
(** [t] represents HTTP multipart request/response body initialized from a
    {!class:Body.readable}. *)

type part
(** [part] is a single part of a multipart body. *)

val make : #Body.readable -> t
(** [make body] is {!type:t} initialized from body [body].

    @raise Invalid_argument if [body] doesn't contain valid MIME boundary value. *)

val boundary : t -> string

val next_part : t -> part
(** [next_part t] reads the next part in [t]. *)

val file_name : part -> string
(** [file_name p] is the file name of part [p]. *)

val form_name : part -> string
(** [form_name p] is the form name of part [p]. *)

val headers : part -> Header.t
(** [headers p] is headers associated with part [p]. *)
