(*-------------------------------------------------------------------------
 * Copyright (c) 2021 Bikal Gurung. All rights reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License,  v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *-------------------------------------------------------------------------*)

(** {i Router} - is a HTTP request routing library for OCaml web applications.

    Given a HTTP {i request_target} and a HTTP {i method}, [Wtr] attempts to
    match the two properties to a pre-defined set of {i route}s. If a match is
    found then the corresponding {i route handler} function of the matched route
    is executed.

    The route matching algorithm is {i radix trie}.

    The {i well typed} part in [Wtr] means that the {i route handler} functions
    can capture and receive arguments which are typed in a variety of OCaml
    types.

    There are two ways to specify {i route} and {i request target}s:

    - {{!section:request_target_dsl} Request Target Combinators} - combinators
      based
    - [\[%routes ""\]] - ppx based which is provided by a separate opam package
      [wtr-ppx]. *)

(** {1 Types} *)

type 'a router
(** A {!type:router} consists of one or many HTTP request {!type:route}s which
    are used to match a given HTTP request target.

    ['a] is a value which is returned by a {i route handler} of the matched
    {i route}. *)

and 'a route
(** {!type:route} is a HTTP request route. A route encapsulates a HTTP
    {!type:method'}, a {!type:request_target} and a {i route handler}. A
    {i route handler} is either of the following:

    - a value of type ['a]
    - or a function which returns a value of type ['a]. *)

and ('a, 'b) request_target
(** {!type:request_target} is a HTTP request target value to be matched. It
    consists of either just a {!type:path} value or a combination of
    {!type:path} and {!type:query} values.

    Example {i request_target} values:

    - [/home/about/] - path only
    - [/home/contact] - path only
    - [/home/contact?name=a&no=123] - path ([/home/contact]) and query
      ([name=a&no=123]). Path and query are delimited by [?] character token if
      both are specified.

    Consult {{!section:request_target_dsl} Request Target DSL} for creating
    values of this type.

    See
    {{:https://datatracker.ietf.org/doc/html/rfc7230#section-5.3} HTTP RFC 7230
      \- request target}. *)

and rest
(** {!type:rest} represents a part of {i request target} from a given path
    component to the rest of a {i request_target}.

    Use {!val:rest_to_string} to convert to string representation. *)

and 'a arg
(** {!type:arg} is a component which can convert a {b path component} or a
    {b query component} [value] token into an OCaml typed value represented by
    ['a]. The successfully converted value is then fed to a {i route handler}
    function as an argument. *)

val rest_to_string : rest -> string
(** [rest_to_string rest] converts [rest] to string. *)

(** {1:arg_func Arg} *)

val arg : string -> (string -> 'a option) -> 'a arg
(** [arg name convert] is {!type:arg} with name [name] and [convert] as the
    function which will convert/decode a string value to an OCaml value of type
    ['a].

    [name] is used during the pretty-printing of {i request_target} by
    {!val:pp_request_target}.

    [convert v] is [Some a] if [convert] can successfully convert [v] to [a].
    Otherwise it is [None].

    Although not strictly necessary if we are only working with
    {i Request Target DSL}, it is recommended to adhere to the following
    convention when creating a custom arg. Such an ['a arg] value can be used
    with both {i Request Target DSL} and [wtr-ppx] ppxes. The convention is as
    follows:

    + Arg value be encapsulated in a module
    + The module define a type called [t]
    + The module define a value called [t] which is of type [t Wtr.arg]
    + The [name] value of the {i arg} match the name of the module.

    An example of such an ['a arg] component - [Fruit.t arg] is as below:

    {[
      module Fruit = struct
        type t = Apple | Orange | Pineapple

        let t : t Wtr.arg =
          Wtr.arg "Fruit" (function
            | "apple" -> Some Apple
            | "orange" -> Some Orange
            | "pineapple" -> Some Pineapple
            | _ -> None)
      end
    ]}

    See {!val:parg} and {!val:qarg} for usage in {i path} and {i query}
    components. *)

(** {1 Routes and Router} *)

val route : Method.t -> ('a, 'b) request_target -> 'a -> 'b route
(** [route method' request_target handler] is a {!type:route}. *)

val router : 'a route list -> 'a router
(** [router routes] is a {!type:router} that is composed of [routes]. *)

val match' : Method.t -> string -> 'a router -> 'a option
(** [match' method' uri router] is [Some a] if [method'] and [request_target]
    together matches one of the routes defined in [router]. Otherwise it is
    None. The value [Some a] is returned by the {i route handler} of the matched
    {i route}.

    The routes are matched based on the lexical order of the routes. This means
    they are matched from {i top to bottom}, {i left to right} and to the
    {i longest match}. See {!val:pp} to visualize the router and the route
    matching mechanism. *)

(** {1:pp Pretty Printers and Debugging}

    Pretty printers can be useful during debugging of routing and/or route
    related issues. *)

val pp_request_target : Format.formatter -> ('a, 'b) request_target -> unit
val pp_route : Format.formatter -> 'b route -> unit
val pp : Format.formatter -> 'a router -> unit

(**/**)

(** Used by wtr/request_target ppx *)
module Private : sig
  val nil : ('b, 'b) request_target
  val rest : (rest -> 'b, 'b) request_target
  val slash : ('b, 'b) request_target
  val exact : string -> ('a, 'b) request_target -> ('a, 'b) request_target

  val query_exact :
    string -> string -> ('a, 'b) request_target -> ('a, 'b) request_target

  val arg : 'c arg -> ('a, 'b) request_target -> ('c -> 'a, 'b) request_target

  val query_arg :
    string -> 'c arg -> ('a, 'b) request_target -> ('c -> 'a, 'b) request_target

  val int : int arg
  val int32 : int32 arg
  val int64 : int64 arg
  val float : float arg
  val bool : bool arg
  val string : string arg
end

(**/**)