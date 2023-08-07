type t = Uri1.authority

let make ?port host = Uri1.make_authority ?port host

let host t = Uri1.authority_host t

let port t = Uri1.authority_port t

let decode s = Uri1.authority s

let encode t =
  let port =
    match Uri1.authority_port t with
    | Some p -> ":" ^ string_of_int p
    | None -> ""
  in
  match Uri1.authority_host t with
  | `IPv6 ip -> Fmt.str "%a%s" Ipaddr.V6.pp ip port
  | `IPv4 ip -> Fmt.str "%a%s" Ipaddr.V4.pp ip port
  | `Domain_name dn -> Fmt.str "%a%s" Domain_name.pp dn port

let equal t0 t1 =
  let t0, p0 = (host t0, port t0) in
  let t1, p1 = (host t1, port t1) in
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
  let t0 = (host t0, port t0) in
  let t1 = (host t1, port t1) in
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
