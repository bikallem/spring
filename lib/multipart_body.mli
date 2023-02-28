(** [Multipart] implements HTTP MIME multipart parsing as defined in
    {{:https://tools.ietf.org/html/rfc7578} RFC 7578}. *)

(** {1 Part} *)

(** [part] is a single part of a multipart request/response body. *)
type 'a part

(** [file_name p] is the file name of part [p]. *)
val file_name : 'a part -> string option

(** [form_name p] is the form name of part [p]. *)
val form_name : 'a part -> string option

(** [headers p] is headers associated with part [p]. *)
val headers : 'a part -> Header.t

(** {1 Reader} *)

(** [reader] represents HTTP multipart request/response body initialized from a
    {!class:Body.readable}. *)
type reader

(** [reader body] is {!type:t} initialized from body [body].

    @raise Invalid_argument
      if [body] doesn't contain valid MIME [boundary] value in "Content-Type"
      header. *)
val reader : #Body.readable -> reader

(** [boundary t] is the MIME boundary value as specified in
    https://www.rfc-editor.org/rfc/rfc7578#section-4.1 *)
val boundary : reader -> string

(** [next_part t] returns the next multipart [part] that is ready to be
    consumed.

    @raise End_of_file if there are not more parts to be read from [t].
    @raise Failure if [t] contains invalid multipart [part] data. *)
val next_part : reader -> reader part

(** [reader_flow p] is the part [p] body {!class:Eio.Flow.source}. *)
val reader_flow : reader part -> Eio.Flow.source
