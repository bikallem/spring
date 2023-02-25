(* Why this design? So that method is extendable. For example WebDAV protocol defines extra methods. I want to cater to that scenario as well. *)

type lowercase_string = string

type t = lowercase_string

let make t = String.lowercase_ascii t

module M = struct
  let get = "get"

  let head = "head"

  let delete = "delete"

  let options = "options"

  let trace = "trace"

  let post = "post"

  let put = "put"

  let patch = "patch"

  let connect = "connect"
end

include M

let to_string t = t

let equal a b = String.equal a b

let pp fmt t = Format.fprintf fmt "%s" (String.uppercase_ascii t)
