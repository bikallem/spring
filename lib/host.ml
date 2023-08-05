type t = Uri1.authority

let make ?port host = (host, port)

let host (host, _) = host

let port (_, port) = port

let decode s = Uri1.authority s

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

let compare_port p0 p1 = Option.compare Int.compare p0 p1

let compare t0 t1 =
  match (t0, t1) with
  | (`IPv6 ip0, p0), (`IPv6 ip1, p1) ->
    let cmp = Ipaddr.V6.compare ip0 ip1 in
    if cmp = 0 then compare_port p0 p1 else cmp
  | (`IPv4 ip0, p0), (`IPv4 ip1, p1) ->
    let cmp = Ipaddr.V4.compare ip0 ip1 in
    if cmp = 0 then compare_port p0 p1 else cmp
  | (`Domain_name dn0, p0), (`Domain_name dn1, p1) ->
    let cmp = Domain_name.compare dn0 dn1 in
    if cmp = 0 then compare_port p0 p1 else cmp
  | (`IPv6 _, _), _ -> 1
  | (`IPv4 _, _), (`IPv6 _, _) -> -1
  | (`Domain_name _, _), (`IPv6 _, _) -> -1
  | (`IPv4 _, _), (`Domain_name _, _) -> 1
  | (`Domain_name _, _), (`IPv4 _, _) -> -1

let pp fmt t = Uri1.pp_authority fmt t
