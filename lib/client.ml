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
  ; cache_mu : Eio.Mutex.t
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
  ; net = (net :> Eio.Net.t)
  ; cache_mu = Eio.Mutex.create ()
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
  Eio.Mutex.lock t.cache_mu;
  Fun.protect
    (fun () ->
      match Cache.find_opt t.cache k with
      | Some (n, s) ->
        if n <= t.maximum_conns_per_host && Eio.Stream.length s = 0 then (
          let conn = tcp_connect t.sw ~host ~service t.net in
          Cache.replace t.cache k (n + 1, s);
          conn)
        else
          let conn = Eio.Stream.take s in
          Cache.replace t.cache k (n, s);
          conn
      | None ->
        let conn = tcp_connect t.sw ~host ~service t.net in
        let s = Eio.Stream.create t.maximum_conns_per_host in
        Cache.replace t.cache k (1, s);
        conn)
    ~finally:(fun () -> Eio.Mutex.unlock t.cache_mu)

type 'a handler = Response.Client.t -> 'a

let do_call t (req : Request.Client.t) f =
  Eio.Time.Timeout.run_exn t.timeout @@ fun () ->
  let host, port = (req.host, req.port) in
  let service =
    match port with
    | Some x -> string_of_int x
    | None -> "80"
  in
  let k = (host, service) in
  let conn = connection t k in
  Eio.Buf_write.with_flow ~initial_size:t.write_initial_size conn (fun writer ->
      Request.Client.write req writer;
      let initial_size = t.read_initial_size in
      let buf_read = Buf_read.of_flow ~initial_size ~max_size:max_int conn in
      let res = Response.Client.parse buf_read in
      let x = f res in
      Eio.Mutex.lock t.cache_mu;
      Fun.protect
        (fun () ->
          match Cache.find_opt t.cache k with
          | Some (n, s) ->
            Eio.Stream.add s conn;
            Cache.replace t.cache k (n, s)
          | None -> ())
        ~finally:(fun () ->
          Response.Client.close res;
          Eio.Mutex.unlock t.cache_mu);
      x)

type url = string

let parse_url url =
  if String.is_prefix ~affix:"https" url then
    raise @@ Invalid_argument "url: https protocol not supported";
  let url =
    if
      (not (String.is_prefix ~affix:"http" url))
      && not (String.is_prefix ~affix:"//" url)
    then "//" ^ url
    else url
  in
  let u = Uri.of_string url in
  let host, port =
    match (Uri.host u, Uri.port u) with
    | None, _ -> raise @@ Invalid_argument "invalid url: host not defined"
    | Some host, port when String.length host > 0 -> (host, port)
    | _ -> raise @@ Invalid_argument "invalid url: host not defined"
  in
  (host, port, Uri.path_and_query u)

let get t url =
  let host, port, resource = parse_url url in
  let req = Request.Client.make ?port ~host ~resource Method.get Body.none in
  do_call t req

let head t url =
  let host, port, resource = parse_url url in
  let req = Request.Client.make ?port ~host ~resource Method.head Body.none in
  do_call t req

let post t body url =
  let host, port, resource = parse_url url in
  let req = Request.Client.make ?port ~host ~resource Method.post body in
  do_call t req

let post_form_values t form_values url =
  let body = Body.form_values_writer form_values in
  post t body url

let call ~conn req =
  let initial_size = 0x1000 in
  Eio.Buf_write.with_flow ~initial_size conn @@ fun writer ->
  Request.Client.write req writer;
  let buf_read = Eio.Buf_read.of_flow ~initial_size ~max_size:max_int conn in
  Response.Client.parse buf_read

let buf_write_initial_size t = t.write_initial_size
let buf_read_initial_size t = t.read_initial_size
let timeout t = t.timeout
