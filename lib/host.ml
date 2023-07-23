type host =
  [ `IPv6 of Ipaddr.V6.t
  | `IPv4 of Ipaddr.V4.t
  | `Domain_name of [ `raw ] Domain_name.t
  ]

type port = int

type t = host * port option

let decode s =
  let buf = Buffer.create 10 in
  let buf_read = Buf_read.of_string s in
  Uri1.authority buf buf_read

let encode (host, port) =
  let port =
    match port with
    | Some p -> ":" ^ string_of_int p
    | None -> ""
  in
  match host with
  | `IPv6 ip -> Fmt.str "%a%s" Ipaddr.V6.pp ip port
  | `IPv4 ip -> Fmt.str "%a%s" Ipaddr.V4.pp ip port
  | `Domain_name dn -> Fmt.str "%a%s" Domain_name.pp dn port

let equal (t0, p0) (t1, p1) =
  let host_equal =
    match (t0, t1) with
    | `IPv6 ip0, `IPv6 ip1 -> Ipaddr.V6.compare ip0 ip1 = 0
    | `IPv4 ip0, `IPv4 ip1 -> Ipaddr.V4.compare ip0 ip1 = 0
    | `Domain_name dn0, `Domain_name dn1 -> Domain_name.equal dn0 dn1
    | _ -> false
  in
  let port_equal = Option.equal ( = ) p0 p1 in
  host_equal && port_equal

let pp fmt t = Uri1.pp_authority fmt t
