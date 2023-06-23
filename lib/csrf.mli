(** [Csrf] implements CSRF protection mechanism employing the
    {b Synchronizer Token Pattern}.

    {b Usage}

    + When a user requests a HTML form - perhpas as GET request - ensure you
      call {!val:enable_protection}. Use {!form_field} to CSRF protect a HTTP
      form submission. Use {!encode_token} with {!token} to CSRF protect request
      in other contexts.

    + When a use submits a HTTP request that needs to be protected from CSRF -
      possibly in a POST request - use {!protect_request}.

    {b References}

    - {{:https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#synchronizer-token-pattern}
        "Synchronizer Token Pattern"} *)

type token = private string
(** [token] is a 32 bytes long randomly generated value. *)

type key = string
(** [key] is an alias for 32 bytes long randomly generated string. *)

type request = Request.server Request.t

type response = Response.server Response.t

type codec
(** [codec] encapsulates decoding CSRF token from request. *)

(** {1 Codec Creation} *)

val form_codec : ?token_name:string -> key -> codec
(** [form_codec key] is [t] where [t] implements CSRF token decoding
    functionality from request forms. The [Content-Type] of requests must be one
    of [application/x-www-form-urlencoded] or [multipart/formdata].

    If [Content-Type] is [multipart/formdata], then the first defined field in
    the form must be the csrf token field.

    [key] is used to decrypt CSRF token.

    @param token_name
      is the name of the form field encapsulating the CSRF token. The default
      value is [__csrf_token__].

      See {!val:form_field} for using CSRF token in a HTML form. See
      {!val:encode_token} for using CSRF token in contexts other than a HTML
      form. *)

(** {1 CSRF Protection} *)

val token_name : codec -> string
(** [token_name codec] is the name of the CSRF token encoded in HTTP request
    artefacts such as session, forms or headers. *)

val token : request -> codec -> token option
(** [token req t] is [Some tok] where [tok] is the CSRF token encapsulated in
    [req]. It is [None] if [req] doesn't hold the CSRF token. *)

val enable_protection : request -> codec -> unit
(** [enable_protection req t] enables csrf protection for request [req]. It does
    this by adding CSRF token to request session if one doesn't already exist. *)

val encode_token : token -> codec -> string
(** [encode_token tok t] is [tok'] where [tok'] contains a CSRF token that is
    encrypted and base64 encoded. [tok'] can be used in HTTP request artefacts
    such as headers, body and request path.

    See {!val:form_field} if you require to use [tok'] in a HTML request form
    setting. *)

exception Csrf_protection_not_enabled

val form_field : request -> codec -> Ohtml.t
(** [form_field req t] is an Ohtml component [v]. [v] contains hidden HTML input
    element which encodes CSRF token. Use [v] in the context of a HTML request
    form.

    Ensure this element is the first defined form field when using in the
    context of a [multipart/formdata] form.

    Example [hello.ohtml] form:

    {[
      fun req csrf ->
      <form action="/transfer.do" method="post" enctype='multipart/form-data'>
        {{ Csrf.form_field req csrf }}
        ...
      </form>
    ]}

    {b Note} Ensure {!val:enable_protection} is called before using this
    function.

    @raise Csrf_protected_not_enabled if CSRF is not enabled for the request. *)

val protect_request :
     ?on_fail:(unit -> response)
  -> codec
  -> (request as 'a)
  -> ('a -> response)
  -> response
(** [protect_request t req f] protects request [req] from CSRF.

    [f] is the lambda that is executed as [f req] after [req] passes CSRF
    protection mechanism.

    [t] determins the CSRF token decoding functionality from [req].

    @param on_fail
      is the lambda that is executed if [req] fails CSRF protection mechanism.
      By default the lambda returns a [Bad Request] response. *)
