(** [Multipart] implements HTTP MIME multipart parsing as defined in
    {{:https://tools.ietf.org/html/rfc7578} RFC 7578}. *)

(** {1 Part} *)

type 'a part
(** [part] is a single part of a multipart request/response body. *)

val file_name : 'a part -> string option
(** [file_name p] is the file name of part [p]. *)

val form_name : 'a part -> string option
(** [form_name p] is the form name of part [p]. *)

val headers : 'a part -> Header.t
(** [headers p] is headers associated with part [p]. *)

(** {1:streaming Reading Parts as Streams}

    The streaming api below supports reading one part at a time. As such, using
    streaming api could result in an efficient memory usage as compared to
    {!val:form}. *)

type reader
(** [reader] is a streaming HTTP multipart request/response body reader. *)

val reader : Body.readable -> reader
(** [reader body] is a reader for multipart body [body].

    @raise Invalid_argument
      if [body] doesn't contain valid MIME [boundary] value in "Content-Type"
      header. *)

val boundary : reader -> string
(** [boundary t] is the MIME boundary value as specified in
    https://www.rfc-editor.org/rfc/rfc7578#section-4.1 *)

val next_part : reader -> reader part
(** [next_part reader] is the next multipart [part] in [reader].

    @raise End_of_file if there are not more parts to be read from [t].
    @raise Failure if [t] contains invalid multipart [part] data. *)

val as_flow : reader part -> Eio.Flow.source
(** [as_flow p] is an eio {!class:Eio.Flow.source} for multipart [p]. *)

val read_all : reader part -> string
(** [read_all p] reads content from multipart [p] until end-of-file. *)

(** {1 Writing Multipart} *)

val make_part :
     ?filename:string
  -> ?headers:Header.t
  -> (#Eio.Flow.source as 'a)
  -> string
  -> 'a part
(** [make_part ~file_name ~headers part_body form_name] creates a mulitpart
    [part] that can be written to a {!class:Body.writable}.

    @param filename is the part [filename] attribute.
    @param headers is HTTP headers for [part] *)

val writable : string -> #Eio.Flow.source part list -> Body.writable
(** [writeable boundary parts] creates a multipart request/response
    {!class:Body.writable} body. *)
