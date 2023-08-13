(** [Multipart] is HTTP MIME multipart codec as defined in
    {{:https://tools.ietf.org/html/rfc7578} RFC 7578}. It is also known more
    popularly as forms in web development.

    It supports both {{!section:streaming} Streaming} and {{!section:form}
    Non-Streaming} processing of multipart/form data. *)

(** {1 Part}

    A part is a form field in a form. It encapsulates two data types:

    + {i Value} is a key/value data value where [key] is the form field name.
    + {i File} holds data from a file. It has additional attributes such as
      headers, and filename in addition to the form field name and actual file
      content. *)

type 'a part
(** [part] is a single part of a multipart request/response body. *)

val file_name : 'a part -> string option
(** [file_name p] is [Some filename] if part [p] is a file part. Otherwise it is
    [None]. *)

val form_name : 'a part -> string
(** [form_name p] is the form field name of part [p]. *)

val headers : 'a part -> Headers.t
(** [headers p] is headers associated with part [p]. It is a
    {!val:Headers.empty} if part [p] is a form value field. *)

(** {1:streaming Reading Parts as Streams}

    The streaming api supports processing multipart/form without a complete
    in-memory representation of data. *)

type stream
(** [stream] is a part/form-field stream. It reads parts/form-fields one at a
    time. *)

val stream : Body.readable -> stream
(** [stream body] creates a stream for multipart encoded HTTP request/response
    body [body].

    @raise Invalid_argument
      if [body] doesn't contain valid MIME [boundary] value in "Content-Type"
      header. *)

val boundary : stream -> string
(** [boundary s] is the Multipart MIME boundary value decoded by [s].

    Boundary value is specified in
    https://www.rfc-editor.org/rfc/rfc7578#section-4.1 *)

val next_part : stream -> stream part
(** [next_part s] is part [p] - the next multipart in stream [s].

    @raise End_of_file if there are no more parts in stream [s].
    @raise Failure
      if stream [s] encounters any error while parsing the next multipart. *)

val as_flow : stream part -> Eio.Flow.source
(** [as_flow p] creates an eio {!class:Eio.Flow.source} for content of part [p]. *)

val read_all : stream part -> string
(** [read_all p] reads content from part [p] until end-of-file. *)

(** {1:form Reading Parts to a Form} *)

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

(** {1:writable Writable Multipart} *)

type writable
(** [writable] is a part that can be written. *)

val writable_value_part : form_name:string -> value:string -> writable part
(** [writable_value_part ~form_name ~value] creates a writable part containing
    string [value] and a form field name of [form_name]. *)

val writable_file_part :
     ?headers:Headers.t
  -> filename:string
  -> form_name:string
  -> #Eio.Flow.source
  -> writable part
(** [writable_file_part ~filename ~form_name body] creates a file form field
    writable part. [body] points to a file source. [filename] is the name of the
    file pointed to by [body] and [form_name] is the name of the form field.

    @param headers
      is a set of HTTP headers for the created part. Default is
      {!val:Headers.empty}. *)

val writable : boundary:string -> writable part list -> Body.writable
(** [writeable ~boundary parts] creates a multipart request/response
    {!type:Body.writable} body with the boundary value [boundary].

    [boundary] is precisely defined at
    https://datatracker.ietf.org/doc/html/rfc7578#section-4.1 *)
