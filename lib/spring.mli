module Version = Version
module Method = Method
include module type of Method.M
module Te = Te
module Transfer_encoding = Transfer_encoding
module Header = Header
include module type of Header.H
module Body = Body
module Status = Status
include module type of Status.S
module Chunked_body = Chunked_body
module Request = Request
module Response = Response
