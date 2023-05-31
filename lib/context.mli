type t
(** [t] represents request handler data context. It encapsulates request,
    session data and anticsrf token for the request. *)

type anticsrf_token = string
(** [anticsrf_token] is a 32 byte long random generated string. Ensure that this
    value is generated from a secure random generation source such as
    [Mirage_crypto_rng.generate]. *)

val make :
     ?session_data:Session.session_data
  -> ?anticsrf_token:anticsrf_token
  -> Request.server_request
  -> t
(** [make request] is [t].

    @param session_data
      is the session data of the context. Default value is [None]
    @param anticsrf_token is the anticsrf token. Default value is [None] *)

val request : t -> Request.server_request
(** [request t] is the HTTP request instance. *)

(** {1 Session} *)

val session_data : t -> Session.session_data option
(** [session_data ctx] is [Some v] if session_data is populated by one of the
    request pipelines. Otherwise is it is [None].

    See {!val:session_pipeline}. *)

val new_session : t -> t
(** [new_session t] is [t = make (request t)] where [t] is initialized with an
    empty session data. *)

val replace_session_data : Session.session_data -> t -> unit
(** [replace_context_session_data session_data t] is [t] with session data in
    [t] replaced by [session_data]. *)

(** {1 Anti-csrf} *)

val anticsrf_token : t -> anticsrf_token option
(** [anticsrf_token t] is [Some tok] if [t] contains an anticsrf token.
    Otherwise it is [None].*)

val replace_anticsrf_token : anticsrf_token -> t -> unit
(** [replace_anticsrf_token tok t] is [t] with anticsrf token [tok], i.e.
    [anticsrf_token t = Some tok]. *)
