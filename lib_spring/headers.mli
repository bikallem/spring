(** A collection of HTTP request and response [field] values. HTTP fields are
    more popularly known as [headers].

    See {{!https://www.rfc-editor.org/rfc/rfc9110#name-fields} Fields} *)

(** {1:header_definition Definition}

    A header definition defines a header's name, its field value codecs and an
    OCaml type representation. *)
module Definition : sig
  type name = private string
  (** [name] is HTTP header name in a canonical format, i.e. the first letter
      and any letter following a hypen([-]) symbol are converted to upper case
      and all other characters are converted to lower-case. For example, the
      canonical header name of [accept-encoding] is [Accept-Encoding]. *)

  val canonical_name : string -> name
  (** [canonical_name s] creates a canonical name from [s]. *)

  type lname = private string
  (** [lname] represents HTTP header name in lowercase form, e.g.
      [Content-Type -> content-type], [Date -> date],
      [Transfer-Encoding -> transfer-encoding] etc.*)

  val lname : string -> lname
  (** [lname s] creates a lowercase header name value from [s]. *)

  val lname_equal : lname -> lname -> bool

  val lname_of_name : name -> lname

  type 'a encode = 'a -> string

  type 'a decode = string -> 'a

  type 'a t
  (** ['a t] represents a header definition. ['a] represents the OCaml type for
      header value as encoded by [t]. *)

  val make : name -> 'a decode -> 'a encode -> 'a t
  (** [make name decode encode] creates header definition with name [name] and
      decoder/encoder function [decode] and [encode] respectively. *)

  val name : 'a t -> name
  (** [name hdr] is the name of [hdr] in canonical form.

      See {!val:canonical_name}. *)

  val decode : string -> 'a t -> 'a
  (** [decode s t] decodes [s] into value [v] using codecs defined in [t]. *)

  val encode : 'a -> 'a t -> string
  (** [encode v t] encodes [v] into its string representation using codecs
      defined in [t]. *)
end

(** {1:standard_header_definitions Standard Header Definitions} *)

val content_length : int Definition.t
(** [content_length] is the [Content-Length] header as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.8.6 *)

val content_type : Content_type.t Definition.t
(** [content_type] is the [Content-Type] header as defined in
    https://httpwg.org/specs/rfc9110.html#field.content-type *)

val content_disposition : Content_disposition.t Definition.t
(** [content_disposition] is the [Content-Disposition] header as defined in
    https://httpwg.org/specs/rfc6266.html#top *)

val host : Host.t Definition.t
(** [host] is the [Host] header as specified in
    https://httpwg.org/specs/rfc9110.html#field.host *)

val trailer : string Definition.t
(** [trailer] is the [Trailer] header as specified in
    https://httpwg.org/specs/rfc9110.html#field.trailer *)

val transfer_encoding : Transfer_encoding.t Definition.t
(** [transfer_encoding] is the [Transfer-Encoding] header as defined in
    https://httpwg.org/specs/rfc9112.html#field.transfer-encoding *)

val te : Te.t Definition.t
(** [te] is the [TE] header as defined in
    https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.4 *)

val connection : string Definition.t

val user_agent : string Definition.t
(** [user_agent] is the [User-Agent] header as specified in
    https://httpwg.org/specs/rfc9110.html#rfc.section.10.1.5 *)

val date : Date.t Definition.t
(** [date] is the [Date] header as defined in
    https://httpwg.org/specs/rfc9110.html#field.date *)

val cookie : Cookie.t Definition.t
(** [cookie] is the [Cookie] header as specified in
    https://datatracker.ietf.org/doc/html/rfc6265#section-4.2 *)

val set_cookie : Set_cookie.t Definition.t
(** [set_cookie] is the [Set-Cookie] header as specified in
    https://datatracker.ietf.org/doc/html/rfc6265 *)

val last_modified : Date.t Definition.t
(** [last_modified] is the [Last-Modified] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#field.last-modified *)

val if_modified_since : Date.t Definition.t
(** [if_modified_since] is the [If-Modified-Since] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#name-if-modified-since *)

val expires : Expires.t Definition.t
(** [expires] is the [Expires] header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#field.expires *)

val etag : Etag.t Definition.t
(** [etag] is the [ETag] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#field.etag *)

val if_none_match : If_none_match.t Definition.t
(** [if_none_match] is the [If-None-Match] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#name-if-none-match *)

val cache_control : Cache_control.t Definition.t
(** [cache_control] is [Cache-Control] header as specified in
    https://www.rfc-editor.org/rfc/rfc9111#name-cache-control *)

(** {1 Headers} *)

type t
(** [t] represents a collection of HTTP headers. *)

val empty : t
(** [empty] is an empty headers value. *)

val singleton : name:string -> value:string -> t
(** [singleton ~name ~value] is [t] initialized with a single header with name
    [name] and value [value]. *)

val is_empty : t -> bool
(** [is_empty t] is [true] if [b] is an empty headers value. *)

val of_list : (string * string) list -> t
(** [of_list l] creates a headers value from an associated list of [name,value]
    [l].*)

val to_list : t -> (Definition.lname * string) list
(** [to_list t] is an associative list of [name] and [value] where [name] is the
    name of a header and [value] is the string representation of a value. *)

val length : t -> int
(** [length t] is count of header values in [t]. *)

(** {1 Add} *)

val add : 'a Definition.t -> 'a -> t -> t
(** [add d v t] adds header with definition [d] and value [v] to [t]. *)

val add_unless_exists : 'a Definition.t -> 'a -> t -> t
(** [add_unless_exists d v t] adds header [h] with definition [d] and value [v]
    to [t] iff header [h] doesn't already exist in [t]. *)

val append : t -> t -> t
(** [append a b] is [t] in which headers in [a] and [b] are added to it. *)

(** {1 Find} *)

val find : 'a Definition.t -> t -> 'a
(** [find d t] is header value [v] if a header with definition [d] exists in
    [t]. [v] is as defined by [d].

    @raise Not_found if header [d] is not found in [t]. *)

val find_opt : 'a Definition.t -> t -> 'a option
(** [find_opt d t] is [Some v] if header [d] exists in [t]. It is [None]
    otherwise. This is an excpetion-safe version of {!val:find}. *)

val find_all : 'a Definition.t -> t -> 'a list
(** [find_all d t] is a list of header values [l] where each item in it matches
    the header as defined in [d]. [l] is [[]] if none of the fields in [t] match
    [d]. *)

val exists : 'a Definition.t -> t -> bool
(** [exists d t] is [true] if header [d] exists in [t]. It is [false] otherwise. *)

(** {1 Update/Remove} *)

val remove_first : 'a Definition.t -> t -> t
(** [remove_first d t ] is [t] with first found header [d] removed in [t]. *)

val remove : 'a Definition.t -> t -> t
(** [remove_all d t] removes all headers in [t] defined by [d]. *)

val replace : 'a Definition.t -> 'a -> t -> t
(** [replace d v t] replaces the value of the first found header [d] with [v] in
    [t]. *)

(** {1 Iter/Filter} *)

val iter : (Definition.lname -> string -> unit) -> t -> unit

val filter : (Definition.lname -> string -> bool) -> t -> t

(** {1 Pretty Printer} *)

val pp : Format.formatter -> t -> unit

(** {1 Parse} *)

val parse : Eio.Buf_read.t -> t

(** {1 Write Header} *)

val write_header : Eio.Buf_write.t -> 'a Definition.t -> 'a -> unit
(** [write_header bw hdr v] writes header/value [hdr/v] to [bw]. *)

val write : Eio.Buf_write.t -> t -> unit
(** [write bw t] writes headers [t] to [bw]. *)
