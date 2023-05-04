let products_v = Products_v.v
let hello_v = Hello_v.v
let layout_v = Layout_v.v
let view ~title body = Spring.Response.ohtml @@ layout_v ~title ~body
