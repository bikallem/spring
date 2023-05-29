type t
(** [t] represents request handler data context. It encapsulates data request
    and session data. *)

val make : ?session_data:Session.session_data -> Request.server_request -> t
(** [make request] is [t].

    @param session_data
      is the session data of the context. Default value is [None] *)

val session_data : t -> Session.session_data option
(** [session_data ctx] is [Some v] if session_data is populated by one of the
    request pipelines. Otherwise is it is [None].

    See {!val:session_pipeline}. *)

val replace_session_data : Session.session_data -> t -> unit
(** [replace_context_session_data session_data t] is [t] with session data in
    [t] replaced by [session_data]. *)

val request : t -> Request.server_request
(** [request t] is the HTTP request instance. *)

val new_session : t -> t
(** [new_session t] is [make (request t)]. *)
