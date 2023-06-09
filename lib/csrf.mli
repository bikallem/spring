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

    [key] is used to decrypt CSRF token.

    @param token_name
      is the name of the form field encapsulating the CSRF token. The default
      value is [__csrf_token__].

      See {!val:ohtml_form_field} for using CSRF token in a HTML form. See
      {!val:encode_csrf_token} for using CSRF token in contexts other than a
      HTML form. *)

val token_name : #t -> string
(** [token_name t] is the name of the CSRF token encoded in HTTP request
    artefacts such as session, forms or headers. *)

val session_token : #Request.server_request -> #t -> token option
(** [session_token req t] is [Some tok] where [tok] is the CSRF token
    encapsulated in [req]. It is [None] if [req] doesn't hold the CSRF token. *)

val decode_csrf_token : #Request.server_request -> #t -> token option
(** [decode_csrf_token req t] is [Some tok] where [tok] is the CSRF token
    encapsulated in [req]. It is [None] if [req] doesn't contain the CSRF token
    as defined by [t]. *)

val enable_csrf_protection : #Request.server_request -> #t -> unit
(** [enable_csrf_protection req t] enables csrf protection for request [req]. *)

val encode_csrf_token : token -> #t -> string
(** [encode_csrf_token tok t] is [tok'] where [tok'] encodes a CSRF token as
    defined by [t]. [tok'] is encrypted and is base64 encoded; such that it can
    be used in HTTP request artefacts such as headers, body and request path. *)

exception Csrf_protection_not_enabled

val ohtml_form_field : #Request.server_request -> #t -> Ohtml.t
(** [ohtml_form_field req t] is [v] of type {!type:Ohtml.t}. [v] contains hidden
    HTML input element which encodes CSRF token in a HTML request form. Ensure
    this element is the first defined form filed when using in the context of
    [multipart/formdata] form.

    Example [hello.ohtml] form:

    {[
      fun req csrf ->
      <form action="/transfer.do" method="post">
        {{ Csrf.ohtml_form_field req csrf }}
        ...
      </form>
    ]}

    {b Note} Ensure {!val:enable_csrf_protection} is called before using this
    function.

    @raise Csrf_protected_not_enabled if CSRF is not enabled for the request. *)

val protect_request :
     ?on_fail:(unit -> Response.server_response)
  -> #t
  -> (#Request.server_request as 'a)
  -> ('a -> Response.server_response)
  -> Response.server_response
(** [protect_request t req f] protects request [req] from CSRF.

    The CSRF protection mechanism employed is {b Synchronizer Token Pattern}.
    This is described in detail at
    https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#synchronizer-token-pattern

    [f] is the lambda that is executed as [f req] after [req] passes CSRF
    protection mechanism.

    @param on_fail
      is the lambda that is executed if [req] fails CSRF protection mechanism.
      By default the lambda returns a [Bad Request] response. *)
