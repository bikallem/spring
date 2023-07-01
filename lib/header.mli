(** A collection of HTTP request and response [field] values. HTTP fields are
    more popularly known as [headers].

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-fields} Fields} *)

(** {1:header_definition Definition}

    A type-safe HTTP header definition primarily defines a header's name, its
    field value codecs and an OCaml type representation. *)
module Definition : sig
  type name = private string
  (** [name] represents HTTP header name value in a canonical format, i.e. the
      first letter and any letter following a hypen([-]) symbol are converted to
      upper case. For example, the canonical header name of [accept-encoding] is
      [Accept-Encoding]. *)

  type lname = private string
  (** [lname] represents HTTP header name in lowercase form, e.g.
      [Content-Type -> content-type], [Date -> date],
      [Transfer-Encoding -> transfer-encoding] etc. See {!val:lname}. *)

  val canonical_name : string -> name
  (** [canonical_name s] converts [s] to a canonical header name value. See
      {!type:name}. *)

  val lname_equal : lname -> lname -> bool

  val lname_of_name : name -> lname

  type 'a encode = 'a -> string

  type 'a decode = string -> 'a

  type 'a t
  (** ['a t] represents a header definition. ['a] represents the OCaml type for
      header value as encoded by [t]. *)

  val make : 'a decode -> 'a encode -> string -> 'a t
  (** [header decoder encoder name] is {!type:header}.

      Use this function define new/custom headers. *)

  val name : 'a t -> name
  (** [name hdr] is the name of [hdr] in canonical form.

      See {!val:canonical_name}. *)

  val decode : string -> 'a t -> 'a
  (** [decode s t] decodes [s] into value [v] using codecs defined in [t]. *)

  val encode : 'a -> 'a t -> string
  (** [encode v t] encodes [v] into its string representation using codecs
      defined in [t]. *)
end

(** {1 Names} *)

type name = private string
(** [name] represents HTTP header name value in a canonical format, i.e. the
    first letter and any letter following a hypen([-]) symbol are converted to
    upper case. For example, the canonical header name of [accept-encoding] is
    [Accept-Encoding]. *)

type lname = private string
(** [lname] represents HTTP header name in lowercase form, e.g.
    [Content-Type -> content-type], [Date -> date],
    [Transfer-Encoding -> transfer-encoding] etc. See {!val:lname}. *)

val canonical_name : string -> name
(** [canonical_name s] converts [s] to a canonical header name value. See
    {!type:name}. *)

val lname : string -> lname
(** [lname s] converts [s] to {!type:lname} *)

val lname_equal : lname -> lname -> bool

val lname_of_name : name -> lname

(** {1 Codecs} *)

type 'a encode = 'a -> string

type 'a decode = string -> 'a

(** {1 Header} *)

type t
(** [t] represents a collection of HTTP headers. *)

(** {2 Type-safe Headers} *)

type 'a header

val header : 'a decode -> 'a encode -> string -> 'a header
(** [header decoder encoder name] is {!type:header}.

    Use this function define new/custom headers. *)

val name : 'a header -> name
(** [name hdr] is the name of [hdr] in canonical form.

    See {!val:canonical_name}. *)

val encode : 'a header -> 'a -> string
(** [encode hdr v] is [txt]. [txt] is a textual representation of [hdr] and [v].
    It is suitable for use in request/response header section. *)

(** {2 Predefined Headers} *)

val content_length : int header
(** [content_length] is the [Content-Length] header as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.8.6 *)

val content_type : Content_type.t header
(** [content_type] is the [Content-Type] header as defined in
    https://httpwg.org/specs/rfc9110.html#field.content-type *)

val content_disposition : Content_disposition.t header
(** [content_disposition] is the [Content-Disposition] header as defined in
    https://httpwg.org/specs/rfc6266.html#top *)

val host : string header
(** [host] is the [Host] header as specified in
    https://httpwg.org/specs/rfc9110.html#field.host *)

val trailer : string header
(** [trailer] is the [Trailer] header as specified in
    https://httpwg.org/specs/rfc9110.html#field.trailer *)

val transfer_encoding : Transfer_encoding.t header
(** [transfer_encoding] is the [Transfer-Encoding] header as defined in
    https://httpwg.org/specs/rfc9112.html#field.transfer-encoding *)

val te : Te.t header
(** [te] is the [TE] header as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.4 *)

val connection : string header

val user_agent : string header
(** [user_agent] is the [User-Agent] header as specified in
    https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.5 *)

val date : Date.t header
(** [date] is the [Date] header as defined in
    https://httpwg.org/specs/rfc9110.html#field.date *)

val cookie : Cookie.t header
(** [cookie] is the [Cookie] header as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

val set_cookie : Set_cookie.t header
(** [set_cookie] is the [Set-Cookie] header as specified in
    https://datatracker.ietf.org/doc/html/rfc6265 *)

val last_modified : Date.t header
(** [last_modified] is the [Last-Modified] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#field.last-modified *)

val if_modified_since : Date.t header
(** [if_modified_since] is the [If-Modified-Since] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#name-if-modified-since *)

val expires : Expires.t header
(** [expires] is the [Expires] header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#field.expires *)

val etag : Etag.t header
(** [etag] is the [ETag] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#field.etag *)

val if_none_match : If_none_match.t header
(** [if_none_match] is the [If-None-Match] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#name-if-none-match *)

val cache_control : Cache_control.t header
(** [cache_control] is [Cache-Control] header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#name-cache-control *)

(** {1 Create} *)

val empty : t

val singleton : name:string -> value:string -> t

val is_empty : t -> bool

val of_list : (string * string) list -> t

val to_list : t -> (lname * string) list

val to_canonical_list : t -> (name * string) list

val length : t -> int

(** {1 Add} *)

val add : t -> 'a header -> 'a -> t

val add_unless_exists : t -> 'a header -> 'a -> t

val append : t -> t -> t

val append_list : t -> (string * string) list -> t

(** {1 Find} *)

val find : t -> 'a header -> 'a

val find_opt : t -> 'a header -> 'a option
(** [find_opt t hdr] is [Some v] is [hdr] exists in [t]. It is [None] otherwise. *)

val find_all : t -> 'a header -> 'a list
(** [find_all t hdr] is [l] - a list of headers matching the definition [hdr] in
    [t]. *)

val exists : t -> 'a header -> bool
(** [exists t hdr] is [true] if [hdr] exists in [t]. It is [false] otherwise. *)

(** {1 Update/Remove} *)

val remove_first : t -> 'a header -> t
(** [remove_first t hdr] removes the first header [hdr] found in [t]. *)

val remove : t -> 'a header -> t
(** [remove_all t hdr] removes all headers in [t] defined by [hdr]. *)

val replace : t -> 'a header -> 'a -> t

(** {1 Iter/Filter} *)

val iter : (lname -> string -> unit) -> t -> unit

val filter : (lname -> string -> bool) -> t -> t

(** {1 Pretty Printer} *)

val easy_fmt : t -> Easy_format.t

val pp : Format.formatter -> t -> unit

(** {1 Parse} *)

val parse : Eio.Buf_read.t -> t

(** {1 Write Header} *)

val write_header : Eio.Buf_write.t -> 'a header -> 'a -> unit
(** [write_header bw hdr v] writes header/value [hdr/v] tow [bw]. *)

val write : Eio.Buf_write.t -> t -> unit
(** [write bw t] writes headers [t] to [bw]. *)
