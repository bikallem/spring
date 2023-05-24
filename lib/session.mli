(** [Session] implements session data store.

    A session data consists of key, value tuple. *)

type nonce = Cstruct.t

type data = string
(** [data] is the encrypted data encoded in a session cookie. *)

type key = string

class virtual t :
  key
  -> object ('a)
       method add : name:string -> value:string -> 'a
       method find_opt : string -> string option
       method virtual encode : nonce -> data
     end

val cookie_session : ?data:data -> key -> t
(** [cookie_session master_key] is a cookie based session [t]. Cookie based
    session encode/decode all session data into a session cookie. The session
    [data] is encrypted/decrypted with [master_key].

    @param data
      is the encrypted data in a session cookie. If not given then session [t]
      is an empty session. Otherwise [t] contains the decoded/decrypted session
      data. *)

val encode : nonce:Cstruct.t -> #t -> data
(** [encode ~nonce t] encrypts session [t] with a nonce value [nonce]. Ensure
    that [nonce] value is generated from a secure source such as
    [Mirage_crypto_rng.generate]. *)

val find_opt : string -> #t -> string option
(** [find_opt name t] is [Some v] where [v] is the session data indexed to id
    [name]. It is otherwise [None]. *)

val add : name:string -> value:string -> (#t as 'a) -> 'a
(** [add ~name ~value t] is [t] with session data tuple of [name,value] added to
    it. *)
