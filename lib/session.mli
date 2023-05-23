(** [Session] implements session data store.

    A session data consists of key, value tuple. *)

type t
(** [t] represents a session. *)

val empty : t
(** [empty] is [t] with empty session data. *)

val of_list : (string * string) list -> t
(** [of_list l] is [t] with a list of session data [l] initialized. *)

val decode : key:string -> string -> t
(** [decode ~key session_data] decodes encrypted [session_data] using [key]. *)

val encode : key:string -> t -> string
(** [encode ~key t] encrypts session [t] with key [key] and a nonce value
    [nonce]. *)

val find_opt : string -> t -> string option
(** [find_opt name t] is [Some v] where [v] is the session data indexed to id
    [name]. It is otherwise [None]. *)

val add : name:string -> value:string -> t -> t
(** [add ~name ~value t] is [t] with session data tuple of [name,value] added to
    it. *)
