type 'a t = { name : string }

let make (type a) name (_x : a) : a t = { name }
let get = { name = "get" }
let head = { name = "head" }
let delete = { name = "delete" }
let options = { name = "options" }
let trace = { name = "trace" }
let post = { name = "post" }
let put = { name = "put" }
let patch = { name = "patch" }
let connect = { name = "connect" }
let equal a b = String.equal a.name b.name
let name t = t.name
let pp fmt t = Format.fprintf fmt "%s" (String.uppercase_ascii t.name)
