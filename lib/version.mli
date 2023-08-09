(** HTTP request/response version. *)

type t = private int * int
(** [t] is HTTP version [(major, minor)] *)

val make : major:int -> minor:int -> t
(** [make ~major ~minor] is HTTP version [t]. [major], [minor] is the
    major/minor HTTP version respectively. *)

val http1_1 : t
(** [http1_1] is HTTP/1.1 version. *)

val http1_0 : t
(** [http1_0] is HTTP/1.0 version. *)

val equal : t -> t -> bool
(** [equal a b] is [true] iff [a] and [b] represents the same HTTP version.
    Otherwise it is [false]. *)

val to_string : t -> string
(** [to_string t] is the string representation of [t]. *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)

val p : t Buf_read.parser
