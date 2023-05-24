(** [Session] implements session functionality in Spring.

    Session can be used to store/retrieve values in a request processing
    pipeline. *)

type nonce = Cstruct.t
(** [nonce] is a 12 byte long randomly generated value. Ensure that this value
    is generated from a secure random generation source such as
    [Mirage_crypto_rng.generate]. *)

type data = string
(** [data] is the encrypted data encoded in a session cookie. *)

type key = string

class virtual t :
  cookie_name:string
  -> object ('a)
       method cookie_name : string
       method session_data : string Map.Make(String).t
       method add : name:string -> value:string -> 'a
       method virtual encode : nonce -> data
       method virtual decode : data -> 'a
     end

val cookie_session : ?cookie_name:string -> key -> t
(** [cookie_session key] is a cookie based session [t]. A cookie based session
    encodes all session data into a session cookie. The session [data] is
    encrypted/decrypted with [key].

    @param cookie_name
      is the cookie name used by [t] to encode/decode session data to/from
      respectively. The default value is [___SPRING_SESSION___]. *)

val cookie_name : #t -> string

val decode : data -> (#t as 'a) -> 'a
(** [decode data t] is [t] updated with [data]. [data] is the encrypted data.
    See {!encode}. *)

val encode : nonce:Cstruct.t -> #t -> data
(** [encode ~nonce t] encrypts session [t] with a nonce value [nonce]. *)

val find_opt : string -> #t -> string option
(** [find_opt name t] is [Some v] where [v] is the session data indexed to id
    [name]. It is otherwise [None]. *)

val add : name:string -> value:string -> (#t as 'a) -> 'a
(** [add ~name ~value t] is [t] with session data tuple of [name,value] added to
    it. *)
