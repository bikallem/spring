type t = private int * string

val make : int -> string -> t
(** [make code phrase] is [t] with status code [code] and status phrase
    [phrase]. *)

module S : sig
  (** Informational *)

  val continue : t
  val switching_protocols : t
  val processing : t
  val early_hints : t

  (** Successful *)

  val ok : t
  val created : t
  val accepted : t
  val non_authoritative_information : t
  val no_content : t
  val reset_content : t
  val partial_content : t

  (** Redirection *)

  val multiple_choices : t
  val moved_permanently : t
  val found : t
  val see_other : t
  val not_modified : t
  val use_proxy : t
  val temporary_redirect : t

  (** Client error *)

  val bad_request : t
  val unauthorized : t
  val payment_required : t
  val forbidden : t
  val not_found : t
  val method_not_allowed : t
  val not_acceptable : t
  val proxy_authentication_required : t
  val request_timeout : t
  val conflict : t
  val gone : t
  val length_required : t
  val precondition_failed : t
  val content_too_large : t
  val uri_too_long : t
  val unsupported_media_type : t
  val range_not_satisfiable : t
  val expectation_failed : t
  val misdirected_request : t
  val unprocessable_content : t
  val locked : t
  val failed_dependency : t
  val too_early : t
  val upgrade_required : t
  val unassigned : t
  val precondition_required : t
  val too_many_requests : t
  val request_header_fields_too_large : t
  val unavailable_for_legal_reasons : t

  (** Server error *)

  val internal_server_error : t
  val not_implemented : t
  val bad_gateway : t
  val service_unavilable : t
  val gateway_timeout : t
  val http_version_not_supported : t
  val variant_also_negotiates : t
  val insufficient_storage : t
  val loop_detected : t
  val network_authentication_required : t
end

include module type of S

val informational : t -> bool
val server_error : t -> bool
val equal : t -> t -> bool
val to_string : t -> string
val pp : Format.formatter -> t -> unit
