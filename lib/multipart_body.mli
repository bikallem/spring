(** [Multipart] implements HTTP MIME multipart parsing as defined in
    {{:https://tools.ietf.org/html/rfc7578} RFC 7578}. *)

type t
(** [t] represents HTTP multipart request/response body initialized from a
    {!class:Body.readable}. *)

val make : #Body.readable -> t
(** [make body] is {!type:t} initialized from body [body].

    @raise Invalid_argument
      if [body] doesn't contain valid MIME [boundary] value in "Content-Type"
      header. *)

val boundary : t -> string
(** [boundary t] is the MIME boundary value as specified in
    https://www.rfc-editor.org/rfc/rfc7578#section-4.1 *)

(** {2 Part} *)

type part
(** [part] is a single part of a multipart request/response body. *)

val next_part : t -> part
(** [next_part t] returns the next multipart [part] that is ready to be
    consumed.

    @raise End_of_file if there are not more parts to be read from [t].
    @raise Failure if [t] contains invalid multipart [part] data. *)

val file_name : part -> string option
(** [file_name p] is the file name of part [p]. *)

val form_name : part -> string option
(** [form_name p] is the form name of part [p]. *)

val headers : part -> Header.t
(** [headers p] is headers associated with part [p]. *)

val flow : part -> Eio.Flow.source
(** [flow p] is the part [p] body {!class:Eio.Flow.source}. *)
