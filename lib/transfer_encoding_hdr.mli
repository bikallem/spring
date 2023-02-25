type encoding

type t

val encoding : string -> encoding

val compress : encoding

val deflate : encoding

val gzip : encoding

val chunked : encoding

val is_empty : t -> bool

val exists : t -> encoding -> bool

val add : t -> encoding -> t

val remove : t -> encoding -> t

val iter : (encoding -> unit) -> t -> unit

val encode : t -> string

val decode : string -> t
