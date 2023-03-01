(** [Date] implements HTTP Date specification as specified in
    https://httpwg.org/specs/rfc9110.html#rfc.section.5.6.7.

    Specifically it supports the following date formats

    - IMF fixdate - [Sun, 06 Nov 1994 08:49:37 GMT]
    - obsolete RFC 850 format - [Sunday, 06-Nov-94 08:49:37 GMT]
    - ANSI C's asctime() format - [Sun Nov  6 08:49:37 1994]

    {b IMF fixdate is the recommended date format.}

    For RFC 850 if the year value is [>= 50] then the cencure is [19] else it is
    [20]. *)

(** [decode v] decodes [v] into a {!val:Ptime.t} value.

    {[
      Date.decode "Sun, 06 Nov 1994 08:49:37 GMT"
    ]} *)
val decode : string -> Ptime.t

(** [encode date] converts [date] into IMF fixdate format. *)
val encode : Ptime.t -> string

(** [now clock] is [ptime] where [ptime] is the current date time value. *)
val now : #Eio.Time.clock -> Ptime.t
