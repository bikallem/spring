(* TODO bikal implement redirect functionality
   TODO bikal implement cookie jar functionality
   TODO bikal allow user to override redirection
   TODO bikal connection caching - idle connection time limit? *)

(* Connection cache using Hashtbl. *)
module Cache = Hashtbl.Make (struct
  type t = Uri.scheme * host * service

  and host = string (* eg. www.example.com *)

  and service = string (* port eg. 80, 8080 *)

  let equal (a : t) (b : t) = Stdlib.( = ) a b

  let hash = Hashtbl.hash
end)

type conn = Eio.Flow.two_way

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
  | conn -> (conn :> Eio.Flow.two_way)
  | exception (Eio.Exn.Io _ as ex) ->
    let bt = Printexc.get_raw_backtrace () in
    Eio.Exn.reraise_with_context ex bt "connecting to %S:%s" host service

let tls_authenticator =
  let authenticator_ref = ref None in
  fun () ->
    match !authenticator_ref with
    | Some x -> x
    | None -> (
      match Ca_certs.authenticator () with
      | Ok a ->
        authenticator_ref := Some a;
        a
      | Error (`Msg m) -> invalid_arg ("failed to trust anchors: " ^ m))

let tls_connect flow =
  let authenticator = tls_authenticator () in
  let config = Tls.Config.client ~authenticator () in
  (Tls_eio.client_of_flow config flow :> Eio.Flow.two_way)

let connection t ((scheme, host, service) as k) =
  Eio.Mutex.lock t.mutex;
  Fun.protect ~finally:(fun () -> Eio.Mutex.unlock t.mutex) @@ fun () ->
  match Cache.find_opt t.cache k with
  | Some (n, s) when n <= t.maximum_conns_per_host && Eio.Stream.length s = 0 ->
    let conn = tcp_connect t.sw ~host ~service t.net in
    let conn =
      match scheme with
      | `Http -> conn
      | `Https -> tls_connect conn
    in
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
  let scheme = Request.scheme req in
  let k = (scheme, host, service) in
  Eio.Time.Timeout.run_exn t.timeout @@ fun () ->
  let conn = connection t k in
  Eio.Buf_write.with_flow ~initial_size:t.write_initial_size conn (fun writer ->
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
        ~finally:(fun () -> Eio.Mutex.unlock t.mutex))

type uri = string

let parse_uri uri =
  let uri =
    if String.is_prefix ~affix:"http" uri then uri else "http://" ^ uri
  in
  match Uri.absolute_uri uri with
  | uri ->
    let scheme = Uri.absolute_uri_scheme uri in
    let host, port = Uri.host_and_port uri in
    let host = Host.make ?port host in
    let path, query = Uri.absolute_uri_path_and_query uri in
    let resource = Uri.pct_encode ?query path in
    (scheme, host, resource)
  | exception _ -> invalid_arg "[uri] invalid HTTP uri."

let make_request ?(body = Body.none) meth (scheme, host, resource) =
  Request.make_client_request ~scheme ~resource host meth body

let get t uri = parse_uri uri |> make_request Method.get |> do_call t

let head t uri = parse_uri uri |> make_request Method.head |> do_call t

let post t body uri =
  parse_uri uri |> make_request ~body Method.post |> do_call t

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
