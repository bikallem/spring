val http_date : #Eio.Time.clock -> string

val decode : string -> Ptime.t

val encode : Ptime.t -> string
