include Stdlib.Option

module Syntax = struct
  let ( let* ) o f = bind o f

  let ( let+ ) o f = map f o
end
