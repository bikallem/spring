(* TODO bikal implement redirect functionality
   TODO bikal implement cookie jar functionality
   TODO bikal allow user to override redirection
   TODO bikal connection caching - idle connection time limit? *)

(* Connection cache using Hashtbl. *)
module Cache = Hashtbl.Make (struct
  type t = host * service

  and host = string (* eg. www.example.com *)

  and service = string (* port eg. 80, 8080 *)

  let equal (a : t) (b : t) = Stdlib.( = ) a b

  let hash = Hashtbl.hash
end)

type conn = < Eio.Net.stream_socket ; Eio.Flow.close >

type connection_stream =
  host_connection_count
  * conn Eio.Stream.t (* total connection * connection stream. *)

and host_connection_count = int

type t =
  { timeout : Eio.Time.Timeout.t
  ; read_initial_size : int
  ; write_initial_size : int
  ; maximum_conns_per_host : int
  ; sw : Eio.Switch.t
  ; net : Eio.Net.t
  ; mutex : Eio.Mutex.t
  ; cache : connection_stream Cache.t
  }

let make
    ?(timeout = Eio.Time.Timeout.none)
    ?(read_initial_size = 0x1000)
    ?(write_initial_size = 0x1000)
    ?(maximum_conns_per_host = 5)
    sw
    (net : #Eio.Net.t) =
  { timeout
  ; read_initial_size
  ; write_initial_size
  ; maximum_conns_per_host
  ; sw
  ; net :> Eio.Net.t
  ; mutex = Eio.Mutex.create ()
  ; cache = Cache.create 1
  }

(* Specialized version of Eio.Net.with_tcp_connect *)
let tcp_connect sw ~host ~service net =
  match
    let rec aux = function
      | [] -> raise @@ Eio.Net.(err (Connection_failure No_matching_addresses))
      | addr :: addrs -> (
        try Eio.Net.connect ~sw net addr
        with Eio.Exn.Io _ when addrs <> [] -> aux addrs)
    in
    Eio.Net.getaddrinfo_stream ~service net host
    |> List.filter_map (function
         | `Tcp _ as x -> Some x
         | `Unix _ -> None)
    |> aux
  with
  | conn -> conn
  | exception (Eio.Exn.Io _ as ex) ->
    let bt = Printexc.get_raw_backtrace () in
    Eio.Exn.reraise_with_context ex bt "connecting to %S:%s" host service

let connection t ((host, service) as k) =
  Eio.Mutex.lock t.mutex;
  Fun.protect ~finally:(fun () -> Eio.Mutex.unlock t.mutex) @@ fun () ->
  match Cache.find_opt t.cache k with
  | Some (n, s) when n <= t.maximum_conns_per_host && Eio.Stream.length s = 0 ->
    let conn = tcp_connect t.sw ~host ~service t.net in
    Cache.replace t.cache k (n + 1, s);
    conn
  | Some (_, s) -> Eio.Stream.take s
  | None ->
    let conn = tcp_connect t.sw ~host ~service t.net in
    let s = Eio.Stream.create t.maximum_conns_per_host in
    Cache.replace t.cache k (1, s);
    conn

type request = Request.client Request.t

type response = Response.client Response.t

type 'a handler = response -> 'a

let do_call t (req : request) f =
  let host =
    match Request.host req with
    | `IPv6 ip -> Ipaddr.V6.to_string ip
    | `IPv4 ip -> Ipaddr.V4.to_string ip
    | `Domain_name nm -> Domain_name.to_string nm
  in
  let service =
    match Request.port req with
    | Some x -> string_of_int x
    | None -> "80"
  in
  let k = (host, service) in
  Eio.Time.Timeout.run_exn t.timeout @@ fun () ->
  let conn = connection t k in
  Eio.Buf_write.with_flow ~initial_size:t.write_initial_size conn
  @@ fun writer ->
  Request.write_client_request req writer;
  let initial_size = t.read_initial_size in
  let buf_read = Buf_read.of_flow ~initial_size ~max_size:max_int conn in
  let res = Response.parse_client_response buf_read in
  let x = f res in
  Eio.Mutex.lock t.mutex;
  Fun.protect
    (fun () ->
      Response.close res;
      let _n, s = Cache.find t.cache k in
      Eio.Stream.add s conn;
      x)
    ~finally:(fun () -> Eio.Mutex.unlock t.mutex)

type uri = string

let parse_uri uri =
  if String.is_prefix ~affix:"https" uri then
    raise @@ Invalid_argument "uri: https protocol not supported";
  let uri =
    if String.is_prefix ~affix:"http" uri || String.is_prefix ~affix:"http" uri
    then uri
    else "http://" ^ uri
  in
  match Uri1.absolute_uri uri with
  | uri ->
    let host, port = Uri1.host_and_port uri in
    let host = Host.make ?port host in
    let path, query = Uri1.absolute_uri_path_and_query uri in
    let resource = Uri1.pct_encode ?query path in
    (host, resource)
  | exception _ -> invalid_arg "[uri] invalid HTTP uri."

let get t uri =
  let host, resource = parse_uri uri in
  let req = Request.make_client_request ~resource host Method.get Body.none in
  do_call t req

let head t uri =
  let host, resource = parse_uri uri in
  let req = Request.make_client_request ~resource host Method.head Body.none in
  do_call t req

let post t body uri =
  let host, resource = parse_uri uri in
  let req = Request.make_client_request ~resource host Method.post body in
  do_call t req

let post_form_values t form_values uri =
  let body = Body.writable_form_values form_values in
  post t body uri

let call ~conn req =
  let initial_size = 0x1000 in
  Eio.Buf_write.with_flow ~initial_size conn @@ fun writer ->
  Request.write_client_request req writer;
  let buf_read = Eio.Buf_read.of_flow ~initial_size ~max_size:max_int conn in
  Response.parse_client_response buf_read

let buf_write_initial_size t = t.write_initial_size

let buf_read_initial_size t = t.read_initial_size

let timeout t = t.timeout
