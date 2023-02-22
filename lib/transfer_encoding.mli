type encoding = [ `compress | `deflate | `gzip | `chunked ]
type t

val empty : t
val is_empty : t -> bool
val exists : encoding -> t -> bool
val add : encoding -> t -> t
val remove : encoding -> t -> t
val iter : (encoding -> unit) -> t -> unit
val encode : t -> string
val decode : string -> t
