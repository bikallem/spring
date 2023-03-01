module Version = Version
module Method = Method

include module type of Method.M

module Te = Te
module Transfer_encoding = Transfer_encoding
module Date = Date
module Content_type = Content_type
module Content_disposition = Content_disposition
module Set_cookie = Set_cookie
module Cookie = Cookie
module Header = Header

include module type of Header.H

(** {1 Body} *)

module Body = Body
module Chunked = Chunked
module Multipart = Multipart

(* {1 Others} *)

module Status = Status

include module type of Status.S

module Request = Request
module Response = Response
module Client = Client
module Server = Server
