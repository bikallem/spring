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

module Data : module type of Map.Make (String)

type session_data = string Data.t

type codec
(** [codec] encapsulates {!type:session_data} encoding/decoding functionality. *)

val cookie_codec : ?cookie_name:string -> key -> codec
(** [cookie_codec key] is a cookie based session [t]. A cookie based session
    encodes all session data into a session cookie. The session [data] is
    encrypted/decrypted with [key].

    @param cookie_name
      is the cookie name used by [t] to encode/decode session data to/from
      respectively. The default value is [___SPRING_SESSION___]. *)

val cookie_name : codec -> string
(** [cookie_name t] is the name of the session cookie in [t]. *)

val decode : data -> codec -> session_data
(** [decode data t] decodes [data] to [session_data] using [t]. *)

val encode : nonce:Cstruct.t -> session_data -> codec -> data
(** [encode ~nonce t] encrypts session [t] with a nonce value [nonce]. *)
