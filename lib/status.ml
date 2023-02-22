type t = int * string

let make code phrase =
  if code < 0 then failwith (Printf.sprintf "code: %d is negative" code)
  else if code < 100 || code > 999 then
    failwith (Printf.sprintf "code: %d is not a three-digit number" code)
  else (code, phrase)

module S = struct
  (* Informational *)
  let continue = (100, "Continue")
  let switching_protocols = (101, "Switching Protocols")
  let processing = (102, "Processing")
  let early_hints = (103, "Early Hints")

  (* Successful *)

  let ok = (200, "OK")
  let created = (201, "Created")
  let accepted = (202, "Accepted")
  let non_authoritative_information = (203, "Non-Authoritative Information")
  let no_content = (204, "No Content")
  let reset_content = (205, "Reset Content")
  let partial_content = (206, "Partial Content")
  (* Redirection *)

  let multiple_choices = (300, "Multiple Choices")
  let moved_permanently = (301, "Moved Permanently")
  let found = (302, "Found")
  let see_other = (303, "See Other")
  let not_modified = (304, "Not Modified")
  let use_proxy = (305, "Use Proxy")
  let temporary_redirect = (306, "Temporary Redirect")

  (* Client error *)
  let bad_request = (400, "Bad Request")
  let unauthorized = (401, "Unauthorized")
  let payment_required = (402, "Payment Required")
  let forbidden = (403, "Forbidden")
  let not_found = (404, "Not Found")
  let method_not_allowed = (405, "Method Not Allowed")
  let not_acceptable = (406, "Not Acceptable")
  let proxy_authentication_required = (407, "Proxy Authentication Required")
  let request_timeout = (408, "Request Timeout")
  let conflict = (409, "Conflict")
  let gone = (410, "Gone")
  let length_required = (411, "Length Required")
  let precondition_failed = (412, "Precondition Failed")
  let content_too_large = (413, "Payload Too Large")
  let uri_too_long = (414, "URI Too Long")
  let unsupported_media_type = (415, "Unsupported Media Type")
  let range_not_satisfiable = (416, "Range Not Satisfiable")
  let expectation_failed = (417, "Expectation Failed")
  let misdirected_request = (421, "Misdirected Request")
  let unprocessable_content = (422, "Unprocessable Content")
  let locked = (423, "Locked")
  let failed_dependency = (424, "Failed Dependency")
  let too_early = (425, "Too Early")
  let upgrade_required = (426, "Upgrade Required")
  let unassigned = (427, "Unassigned")
  let precondition_required = (428, "Precondition Required")
  let too_many_requests = (429, "Too Many Requests")
  let request_header_fields_too_large = (431, "Request Header Fields Too Large")
  let unavailable_for_legal_reasons = (451, "Unavailable For Legal Reasons")

  (* Server error *)
  let internal_server_error = (500, "Internal Server Error")
  let not_implemented = (501, "Not Implemented")
  let bad_gateway = (502, "Bad Gateway")
  let service_unavilable = (503, "Service Unavailable")
  let gateway_timeout = (504, "Gateway Timeout")
  let http_version_not_supported = (505, "HTTP Version Not Supported")
  let variant_also_negotiates = (506, "Variant Also Negotiates")
  let insufficient_storage = (507, "Insufficient Storage")
  let loop_detected = (508, "Loop Detected")
  let network_authentication_required = (511, "Network Authentication Required")
end

include S

let equal (code_a, _) (code_b, _) = code_a = code_b
let to_string (code, phrase) = string_of_int code ^ " " ^ phrase
let pp fmt t = Format.fprintf fmt "%s" (to_string t)
