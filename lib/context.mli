type t
(** [t] represents request handler data context. It encapsulates request,
    session data and anticsrf token for the request. *)

type anticsrf_token = private string
(** [anticsrf_token] is a 32 byte long random string which is base64 encoded. *)

val make : ?session_data:Session.session_data -> Request.server_request -> t
(** [make request] is [t].

    @param session_data
      is the session data of the context. Default value is [None]
    @param anticsrf_token is the anticsrf token. Default value is [None]. *)

val request : t -> Request.server_request
(** [request t] is the HTTP request instance. *)

(** {1 Session} *)

val session_data : t -> Session.session_data option
(** [session_data ctx] is [Some v] if session_data is populated by one of the
    request pipelines. Otherwise is it is [None].

    See {!val:session_pipeline}. *)

val reset_session : t -> unit
(** [reset_session t] resets the [session_data t] value such that it is [None]. *)

val replace_session_data : Session.session_data -> t -> unit
(** [replace_context_session_data session_data t] is [t] with session data in
    [t] replaced by [session_data]. After this operation
    [session_data t = Some session_data]. *)

(** {1 Anti-csrf} *)

val init_anticsrf_token : t -> unit
(** [init_anticsrf_token t] resets [t] with anticsrf token value [tok] such that
    [anticsrf_token t = Some tok]. *)

val anticsrf_token : t -> anticsrf_token option
(** [anticsrf_token t] is [Some tok] if [t] contains an anticsrf token.
    Otherwise it is [None].

    Ensure you call {!val:init_anticsrf_token t} before you call this function
    if you wish to avail yourself of anticsrf token value. *)
