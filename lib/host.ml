type host =
  [ `IPv6 of Ipaddr.V6.t
  | `IPv4 of Ipaddr.V4.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]

type port = int

type t = host * port option

let v t = t

let decode s =
  let buf = Buffer.create 10 in
  let buf_read = Buf_read.of_string s in
  Uri1.authority buf buf_read

let pp fmt t = Uri1.pp_authority fmt t
