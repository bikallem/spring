type t

(** {1 Encoding} *)

type encoding

val encoding : string -> encoding

val compress : encoding

val deflate : encoding

val gzip : encoding

val chunked : encoding

(** {1 Add, Remove, Find} *)

val singleton : encoding -> t

val is_empty : t -> bool

val exists : t -> encoding -> bool

val add : t -> encoding -> t

val remove : t -> encoding -> t

val iter : (encoding -> unit) -> t -> unit

(** {1 Codec} *)

val encode : t -> string

val decode : string -> t
