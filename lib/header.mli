(** [Header]

    An extendable and type-safe HTTP Header. *)

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

(** {1 Codecs} *)

type 'a encode = 'a -> string
type 'a decode = string -> 'a

(** {1 Header} *)

type t
(** [t] represents a collection of HTTP headers. *)

(** {2 Type-safe Headers} *)

type 'a header

val header : 'a decode -> 'a encode -> string -> 'a header
(** [header decoder encoder name] is {!type:header}. *)

module H : sig
  val content_length : int header
  val content_type : string header
  val host : string header
  val trailer : string header
  val transfer_encoding : Transfer_encoding_hdr.t header
  val te : Te_hdr.t header
  val connection : string header
  val user_agent : string header
  val date : string header
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

val find : t -> 'a header -> 'a
val find_opt : t -> 'a header -> 'a option
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
