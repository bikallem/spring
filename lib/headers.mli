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

val host : string Definition.t
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

(** {1 Create} *)

val empty : t

val singleton : name:string -> value:string -> t

val is_empty : t -> bool

val of_list : (string * string) list -> t

val to_list : t -> (Definition.lname * string) list

val to_canonical_list : t -> (Definition.name * string) list

val length : t -> int

(** {1 Add} *)

val add : t -> 'a Definition.t -> 'a -> t

val add_unless_exists : t -> 'a Definition.t -> 'a -> t

val append : t -> t -> t

val append_list : t -> (string * string) list -> t

(** {1 Find} *)

val find : t -> 'a Definition.t -> 'a

val find_opt : t -> 'a Definition.t -> 'a option
(** [find_opt t hdr] is [Some v] is [hdr] exists in [t]. It is [None] otherwise. *)

val find_all : t -> 'a Definition.t -> 'a list
(** [find_all t hdr] is [l] - a list of headers matching the definition [hdr] in
    [t]. *)

val exists : t -> 'a Definition.t -> bool
(** [exists t hdr] is [true] if [hdr] exists in [t]. It is [false] otherwise. *)

(** {1 Update/Remove} *)

val remove_first : t -> 'a Definition.t -> t
(** [remove_first t hdr] removes the first header [hdr] found in [t]. *)

val remove : t -> 'a Definition.t -> t
(** [remove_all t hdr] removes all headers in [t] defined by [hdr]. *)

val replace : t -> 'a Definition.t -> 'a -> t

(** {1 Iter/Filter} *)

val iter : (Definition.lname -> string -> unit) -> t -> unit

val filter : (Definition.lname -> string -> bool) -> t -> t

(** {1 Pretty Printer} *)

val easy_fmt : t -> Easy_format.t

val pp : Format.formatter -> t -> unit

(** {1 Parse} *)

val parse : Eio.Buf_read.t -> t

(** {1 Write Header} *)

val write_header : Eio.Buf_write.t -> 'a Definition.t -> 'a -> unit
(** [write_header bw hdr v] writes header/value [hdr/v] tow [bw]. *)

val write : Eio.Buf_write.t -> t -> unit
(** [write bw t] writes headers [t] to [bw]. *)
