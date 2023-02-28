(** [Header]

    An extendable and type-safe HTTP Header. *)

(** {1 Names} *)

(** [name] represents HTTP header name value in a canonical format, i.e. the
    first letter and any letter following a hypen([-]) symbol are converted to
    upper case. For example, the canonical header name of [accept-encoding] is
    [Accept-Encoding]. *)
type name = private string

(** [lname] represents HTTP header name in lowercase form, e.g.
    [Content-Type -> content-type], [Date -> date],
    [Transfer-Encoding -> transfer-encoding] etc. See {!val:lname}. *)
type lname = private string

(** [canonical_name s] converts [s] to a canonical header name value. See
    {!type:name}. *)
val canonical_name : string -> name

(** [lname s] converts [s] to {!type:lname} *)
val lname : string -> lname

val lname_equal : lname -> lname -> bool

(** {1 Codecs} *)

type 'a encode = 'a -> string

type 'a decode = string -> 'a

(** {1 Header} *)

(** [t] represents a collection of HTTP headers. *)
type t

(** {2 Type-safe Headers} *)

type 'a header

(** [header decoder encoder name] is {!type:header}. *)
val header : 'a decode -> 'a encode -> string -> 'a header

module H : sig
  val content_length : int header

  val content_type : Content_type.t header

  val content_disposition : Content_disposition.t header

  val host : string header

  val trailer : string header

  val transfer_encoding : Transfer_encoding_hdr.t header

  val te : Te_hdr.t header

  val connection : string header

  val user_agent : string header

  val date : Ptime.t header

  val cookie : Cookie.t header

  val set_cookie : Set_cookie.t header
end

include module type of H

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

val find : t -> 'a header -> 'a option

val find_all : t -> 'a header -> 'a list

val exists : t -> 'a header -> bool

(** {1 Update/Remove} *)

val remove : t -> 'a header -> t

val replace : t -> 'a header -> 'a -> t

val clean_dup : t -> t

(** {1 Iter/Filter} *)

val iter : (lname -> string -> unit) -> t -> unit

val filter : (lname -> string -> bool) -> t -> t

(** {1 Pretty Printer} *)

val easy_fmt : t -> Easy_format.t

val pp : Format.formatter -> t -> unit

(** {1 Parse} *)

val parse : Eio.Buf_read.t -> t

(** {1 Write Header} *)

(** [write_header f name value] writes header [name] and [value] using writer
    [f]. *)
val write_header : (string -> unit) -> string -> string -> unit

(** [write t f] writes headers [t] using writer [f]. *)
val write : t -> (string -> unit) -> unit
