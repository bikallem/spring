type token = private string
(** [token] is a 32 bytes long randomly generated value. *)

type key = string
(** [key] is an alias for 32 bytes long randomly generated string. *)

(** [t] encapsulates decoding CSRF token from request. *)
class virtual t :
  token_name:string
  -> key:key
  -> object
       method token_name : string
       method encode_csrf_token : token -> string
       method virtual decode_csrf_token : Request.server_request -> token option
     end

val csrf_protected_form : ?token_name:string -> key -> t
(** [csrf_protected_form key] is [t] where [t] implements CSRF token decoding
    functionality from request forms. The [Content-Type] of requests must be one
    of [application/x-www-form-urlencoded] or [multipart/formdata].

    If [Content-Type] is [multipart/formdata], then the first defined field in
    the form must be the csrf token field.

    [key] is used to decrypt the token.

    Example form request in HTML:

    {[
      <form action="/transfer.do" method="post">
        <input type="hidden" name="__csrf_token__" value="OWY4NmQwODE4ODRjN2Q2NTlhMmZlYWEwYzU1YWQwMTVhM2JmNGYxYjJiMGI4MjJjZDE1ZDZMGYwMGEwOA==">
        ...
      </form>
    ]}
    @param token_name
      is the name of the form field encapsulating the CSRF token. The default
      value is [__csrf_token__]. *)

val session_token : #Request.server_request -> #t -> token option
(** [session_token req t] is [Some tok] where [tok] is the CSRF token
    encapsulated in [req]. It is [None] if [req] doesn't hold the CSRF token. *)

val enable_csrf_protection : #Request.server_request -> #t -> unit
(** [enable_csrf_protection req t] enables csrf protection for request [req]. *)

val decode_csrf_token : #Request.server_request -> #t -> token option
(** [decode_csrf_token req t] is [Some tok] where [tok] is the CSRF token
    encapsulated in [req]. It is [None] if [req] doesn't contain the CSRF token
    as defined by [t]. *)

val encode_csrf_token : token -> #t -> string
(** [encode_csrf_token tok t] is [tok'] where [tok'] is encoded as defined by
    [t]. Encoding here means [tok] is encrypted and is base64 encoded into
    [tok']. *)

exception Csrf_protection_not_enabled

val ohtml_form_field : #Request.server_request -> #t -> Ohtml.t
(** [csrf_form_field req t] is [v] where [v] can be used in [.ohtml] views.

    @raise Csrf_protected_not_enabled if CSRF is not enabled for the request. *)

val protect_request :
     ?on_fail:(unit -> Response.server_response)
  -> ('a -> Response.server_response)
  -> #t
  -> (#Request.server_request as 'a)
  -> Response.server_response
