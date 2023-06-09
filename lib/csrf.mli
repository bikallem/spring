(** [Csrf] implements CSRF protection mechanism employing the
    {b Synchronizer Token Pattern}.

    {b Usage}

    + When a user requests a HTML form - perhpas as GET request - ensure you
      call {!val:enable_csrf_protection}. Use {!ohtml_form_field} to CSRF
      protect a HTTP form submission. Use {!encode_csrf_token} with
      {!session_token} to CSRF protect request in other contexts.

    + When a use submits a HTTP request that needs to be protected from CSRF -
      possibly in a POST request - use {!protect_request}.

    {b References}

    - {{:https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#synchronizer-token-pattern}
        "Synchronizer Token Pattern"} *)

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

(** {1 Creation} *)

val csrf_form_codec : ?token_name:string -> key -> t
(** [csrf_form_codec key] is [t] where [t] implements CSRF token decoding
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

(** {1 CSRF Protection} *)

val token_name : #t -> string
(** [token_name t] is the name of the CSRF token encoded in HTTP request
    artefacts such as session, forms or headers. *)

val session_token : #Request.server_request -> #t -> token option
(** [session_token req t] is [Some tok] where [tok] is the CSRF token
    encapsulated in [req]. It is [None] if [req] doesn't hold the CSRF token. *)

val enable_csrf_protection : #Request.server_request -> #t -> unit
(** [enable_csrf_protection req t] enables csrf protection for request [req]. It
    does this by adding CSRF token to request session if one doesn't already
    exist. *)

val encode_csrf_token : token -> #t -> string
(** [encode_csrf_token tok t] is [tok'] where [tok'] contains a CSRF token that
    is encrypted and base64 encoded. [tok'] can be used in HTTP request
    artefacts such as headers, body and request path.

    See {!val:ohtml_form_field} if you require to use [tok'] in a HTML request
    form setting. *)

exception Csrf_protection_not_enabled

val ohtml_form_field : #Request.server_request -> #t -> Ohtml.t
(** [ohtml_form_field req t] is an Ohtml component [v]. [v] contains hidden HTML
    input element which encodes CSRF token. Use [v] in the context of a HTML
    request form.

    Ensure this element is the first defined form field when using in the
    context of a [multipart/formdata] form.

    Example [hello.ohtml] form:

    {[
      fun req csrf ->
      <form action="/transfer.do" method="post" enctype='multipart/form-data'>
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

    [f] is the lambda that is executed as [f req] after [req] passes CSRF
    protection mechanism.

    [t] determins the CSRF token decoding functionality from [req].

    @param on_fail
      is the lambda that is executed if [req] fails CSRF protection mechanism.
      By default the lambda returns a [Bad Request] response. *)