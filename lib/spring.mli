module Version = Version
module Method = Method

include module type of Method.M

module Te_hdr = Te_hdr
module Transfer_encoding_hdr = Transfer_encoding_hdr
module Date = Date
module Content_type = Content_type
module Content_disposition = Content_disposition
module Set_cookie = Set_cookie
module Cookie = Cookie
module Header = Header

include module type of Header.H

(** {1 Body} *)

module Body = Body
module Chunked_body = Chunked_body
module Multipart_body = Multipart_body

(* {1 Others} *)

module Status = Status

include module type of Status.S

module Request = Request
module Response = Response
module Client = Client
module Server = Server
