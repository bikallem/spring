(** [Date] implements HTTP Date specification as specified in
    https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.7.

    Specifically it supports the following date formats

    - IMF fixdate - [Sun, 06 Nov 1994 08:49:37 GMT]
    - obsolete RFC 850 format - [Sunday, 06-Nov-94 08:49:37 GMT]
    - ANSI C's asctime() format - [Sun Nov  6 08:49:37 1994]

    {b IMF fixdate is the recommended date format.}

    For RFC 850 if the year value is [>= 50] then the century value of the year
    is [19] else it is [20]. *)

type t

val of_ptime : Ptime.t -> t
(** [of_ptime ptime] is HTTP timestamp created using date/time values in
    [ptime].

    {b Note} Decimal fractional seconds in [ptime] are truncated since HTTP
    timestamp doesn't represent time beyond the seconds. *)

val of_float_s : float -> t option
(** [of_float_s d] is the HTTP timestamp [t] created using date/time values in
    [d].

    [d] is floating point seconds since 00:00:00 GMT, Jan. 1, 1970. It is
    compatible with {!val:Unix.gettimeofday} value.

    [t] is [None] if [d] is not within valid HTTP timestamp range.

    {b Note} Decimal fractional seconds in [ptime] are truncated since HTTP
    timestamp doesn't represent time beyond the seconds. *)

val decode : string -> t
(** [decode v] decodes [v] into a {!val:Ptime.t} value.

    {[
      Date.decode "Sun, 06 Nov 1994 08:49:37 GMT"
    ]} *)

val encode : t -> string
(** [encode date] converts [date] into IMF fixdate format. *)

val now : #Eio.Time.clock -> t
(** [now clock] is [t] where [t] is the current datetime timestamp. *)

(** {1 Comparision} *)

val compare : t -> t -> int
(** [compare a b] is [-1] if [a] is less than [b], [1] if [a] is greater than
    [b] and [0] if [a] is equal to [b]. *)

val equal : t -> t -> bool
(** [equal a b] is [true] if [a] and [b] are the same values. Otherwise it is
    [false].

    [equal a b = (compare a b = 0)]. *)

val is_later : t -> than:t -> bool
(** [is_later t ~than] is [true] iff [compare t than = 1]. *)

val is_earlier : t -> than:t -> bool
(** [is_earlier t ~than] is [true] iff [compare t than = -1]. *)

(** {1 Pretty Printing} *)

val pp : Format.formatter -> t -> unit
(** [pp fmt t] pretty prints [t] onto [fmt]. *)
