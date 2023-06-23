(** [Multipart] implements HTTP MIME multipart parsing as defined in
    {{:https://tools.ietf.org/html/rfc7578} RFC 7578}. *)

(** {1 Part} *)

type 'a part
(** [part] is a single part of a multipart request/response body. *)

val file_name : 'a part -> string option
(** [file_name p] is the file name of part [p]. *)

val form_name : 'a part -> string
(** [form_name p] is the form name of part [p]. *)

val headers : 'a part -> Header.t
(** [headers p] is headers associated with part [p]. *)

(** {1:streaming Reading Parts as Streams}

    The streaming api supports reading one part at a time. As such, using
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

(** {1 Reading Parts to a Form} *)

type form
(** [form] is a parsed, in-memory multipart/formdata representation. *)

val form : Body.readable -> form
(** [form readable] reads all parts of a multipart encoded [readable] into a
    {!type:Form.t}.

    The parts are read into a memory buffer; therefore it may not be an
    efficient way to read a multipart [readable] when there are a large number
    of parts or if individual parts are large.

    As an alternative memory efficient mechanism to this function, see
    {{!section:streaming} Streaming API}. *)

type value_field = string
(** [value_field] is a string value form field. *)

type file_field = string part
(** [file_field] is a form field which encapsulates a file content. *)

val file_content : file_field -> string
(** [file_content ff] is the content of file field [ff]. *)

val find_value_field : string -> form -> value_field option
(** [find_value_field name] is [Some v] if a form field with name [name] exists
    in [t]. Otherwise it is [None]. *)

val find_file_field : string -> form -> file_field option
(** [find_file_field name] is [Some ff] if a form field of type
    {!type:file_field} with name [name] exists in [t]. Otherwise it is [None]. *)

(** {1 Writing Multipart} *)

type writable

val writable_value_part : form_name:string -> value:string -> writable part
(** [writable_value_part ~form_name ~value] creates a writable part containing
    string [value] and a form field name of [form_name]. *)

val writable_file_part :
     ?headers:Header.t
  -> filename:string
  -> form_name:string
  -> #Eio.Flow.source
  -> writable part
(** [writable_file_part ~filename ~form_name body] creates a file form field
    writable part. [body] points to a file source. [filename] is the name of the
    file pointed to by [body] and [form_name] is the name of the form field.

    @param headers
      is a set of HTTP headers for the created part. Default is
      {!val:Header.empty}. *)

val writable : boundary:string -> writable part list -> Body.writable
(** [writeable ~boundary parts] creates a multipart request/response
    {!type:Body.writable} body with the boundary value [boundary]. *)
