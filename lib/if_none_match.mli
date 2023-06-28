(** HTTP [If-None-Match] header as specified in
    https://www.rfc-editor.org/rfc/rfc9110#field.if-match *)

type t
(** [t] is a [If-None-Match] header value. *)

val any : t
(** [any] is the [*] [If-None-Match] value. *)

val make : Etag.t list -> t
(** [make entity_tags] creates [If-None-Match] value from a list of Etag values
    [entity_tags].

    @raise Invalid_arg if [entity_tags = \[\]]. *)

val entity_tags : t -> Etag.t list
(** [entity_tags t] is a list of entity tags as exists in [t]. It is [\[\]] if
    [any t = true]. *)

val is_any : t -> bool
(** [is_any t] is [true] if [t] is an {!val:any} value. Otherwise it is [false]. *)

val contains_entity_tag : (Etag.t -> bool) -> t -> bool
(** [contains_entity_tag f t] is [b]. [b] is [true] if [f] evaluates to [true]
    for at least one of the entity tags in [t]. [etag]. Otherwise it is [false].

    If [any t = true] then [b] is always [true]. *)

val decode : string -> t
(** [decode s] decodes raw [If-None-Match] header value [s] into [t]. *)

val encode : t -> string
(** [encode t] encodes [t] into a raw [If-None-Match] header value. *)
