(*-------------------------------------------------------------------------
 * Copyright (c) 2021 Bikal Gurung. All rights reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License,  v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *-------------------------------------------------------------------------*)

module String = Stdlib.String

(* Arg id type. *)
type 'a witness = ..
type (_, _) eq = Eq : ('a, 'a) eq

module type Ty = sig
  type t

  val witness : t witness
  val eq : 'a witness -> ('a, t) eq option
end

type 'a id = (module Ty with type t = 'a)

let new_id (type a) () =
  let module Ty = struct
    type t = a
    type 'a witness += Ty : t witness

    let witness = Ty

    let eq (type b) : b witness -> (b, t) eq option = function
      | Ty -> Some Eq
      | _ -> None
  end in
  (module Ty : Ty with type t = a)

let eq : type a b. a id -> b id -> (a, b) eq option =
 fun (module TyA) (module TyB) -> TyB.eq TyA.witness

type 'a t = { root : 'a route option; routes : (node * 'a t) list }

and ('a, 'b) request_target =
  | Nil : (Request.server_request -> 'b, 'b) request_target
  | Rest : (rest -> Request.server_request -> 'b, 'b) request_target
  | Slash : (Request.server_request -> 'b, 'b) request_target
  | Exact : string * ('a, 'b) request_target -> ('a, 'b) request_target
  | Query_exact :
      string * string * ('a, 'b) request_target
      -> ('a, 'b) request_target
  | Arg : 'c arg * ('a, 'b) request_target -> ('c -> 'a, 'b) request_target
  | Query_arg :
      string * 'c arg * ('a, 'b) request_target
      -> ('c -> 'a, 'b) request_target

(** Existential to encode request_target component/node type. *)
and node =
  | NSlash : node
  | NRest : node
  | NExact : string -> node
  | NQuery_exact : string * string -> node
  | NMethod : Method.t -> node
  | NArg : 'c arg -> node
  | NQuery_arg : string * 'c arg -> node

and 'c route = Route : Method.t * ('a, 'c) request_target * 'a -> 'c route
and rest = string

and 'a arg =
  { name : string
  ; (* name e.g. int, float, bool, string etc *)
    convert : string -> 'a option
  ; id : 'a id
  }

and arg_value = Arg_value : 'c arg * 'c -> arg_value

(* Arg *)

let arg name convert =
  let id = new_id () in
  { name; convert; id }

let int_d = arg "int" int_of_string_opt
let int32_d = arg "int32" Int32.of_string_opt
let int64_d = arg "int64" Int64.of_string_opt
let float_d = arg "float" float_of_string_opt
let string_d = arg "string" (fun a -> Some a)
let bool_d = arg "bool" bool_of_string_opt

external rest_to_string : rest -> string = "%identity"

(* Routes and Router *)

let route : Method.t -> ('a, 'b) request_target -> 'a -> 'b route =
 fun method' request_target f -> Route (method', request_target, f)

let empty = { root = None; routes = [] }

let node_equal a b =
  match (a, b) with
  | NSlash, NSlash -> true
  | NRest, NRest -> true
  | NExact exact1, NExact exact2 -> String.equal exact2 exact1
  | NQuery_exact (name1, value1), NQuery_exact (name2, value2) ->
    String.equal name1 name2 && String.equal value1 value2
  | NMethod meth1, NMethod meth2 -> Method.equal meth1 meth2
  | NArg arg, NArg arg' -> (
    match eq arg'.id arg.id with
    | Some Eq -> true
    | None -> false)
  | NQuery_arg (name1, arg1), NQuery_arg (name2, arg2) -> (
    String.equal name1 name2
    &&
    match eq arg1.id arg2.id with
    | Some Eq -> true
    | None -> false)
  | _ -> false

let rec node_of_request_target : type a b. (a, b) request_target -> node list =
  function
  | Nil -> []
  | Slash -> [ NSlash ]
  | Rest -> [ NRest ]
  | Exact (exact1, request_target) ->
    NExact exact1 :: node_of_request_target request_target
  | Query_exact (name, value, request_target) ->
    NQuery_exact (name, value) :: node_of_request_target request_target
  | Arg (arg, request_target) ->
    NArg arg :: node_of_request_target request_target
  | Query_arg (name, arg, request_target) ->
    NQuery_arg (name, arg) :: node_of_request_target request_target

let add_route : 'a route -> 'a t -> 'a t =
 fun (Route (method', request_target, _) as route) t ->
  let rec loop t nodes =
    match nodes with
    | [] -> { t with root = Some route }
    | node :: nodes ->
      let root =
        List.find_opt (fun (node', _) -> node_equal node node') t.routes
      in
      let routes =
        match root with
        | Some _ ->
          List.map
            (fun (node', t') ->
              if node_equal node node' then (node', loop t' nodes)
              else (node', t'))
            t.routes
        | None -> (node, loop empty nodes) :: t.routes
      in
      { t with routes }
  in
  let nodes = NMethod method' :: node_of_request_target request_target in
  loop t nodes

let rec compile : 'a t -> 'a t =
 fun t ->
  { t with
    routes = List.rev t.routes |> List.map (fun (node, t) -> (node, compile t))
  }

let make routes =
  List.fold_left (fun a r -> add_route r a) empty routes |> compile

let rec drop : 'a list -> int -> 'a list =
 fun l n ->
  match l with
  | _ :: tl when n > 0 -> drop tl (n - 1)
  | t -> t

let rec match' : #Request.server_request -> 'a t -> 'a option =
 fun req t ->
  let req = (req :> Request.server_request) in
  let request_target = Request.resource req in
  let method' = Request.meth req in
  (* split request_target into path and query tokens *)
  let request_target' = request_target |> String.trim |> Uri.of_string in
  let path_tokens =
    Uri.path request_target' |> String.split_on_char '/' |> List.tl
    |> List.map (fun tok -> `Path tok)
  in
  let query_tokens =
    Uri.query request_target'
    |> List.map (fun (k, values) -> List.map (fun v' -> `Query (k, v')) values)
    |> List.concat
  in
  let request_target_tokens = path_tokens @ query_tokens in
  (* Matching algorithm overview:

     1. First match the HTTP method as all routes always start with a HTTP method
     2. Then follow the trie nodes as suggested by the trie algorithm.
  *)
  let rec try_match t arg_values request_target_tokens matched_token_count =
    match request_target_tokens with
    | [] ->
      Option.map
        (fun (Route (_, request_target, f)) ->
          exec_route_handler req f (request_target, List.rev arg_values))
        t.root
    | tok :: request_target_tokens ->
      let rest_matched, matched_token_count, matched_node =
        match_request_path tok arg_values matched_token_count t.routes
      in
      Option.bind matched_node (fun (t', arg_values) ->
          let matched_tok_count = matched_token_count + 1 in
          if rest_matched then
            (try_match [@tailcall]) t' arg_values [] matched_tok_count
          else
            (try_match [@tailcall]) t' arg_values request_target_tokens
              matched_tok_count)
  and match_request_path tok arg_values (matched_tok_count : int) nodes =
    match (tok, nodes) with
    | _, [] -> (false, matched_tok_count, None)
    | `Path v, (NArg arg, t') :: nodes -> (
      match arg.convert v with
      | Some v ->
        (false, matched_tok_count, Some (t', Arg_value (arg, v) :: arg_values))
      | None -> match_request_path tok arg_values matched_tok_count nodes)
    | `Path v, (NExact exact, t') :: _ when String.equal exact v ->
      (false, matched_tok_count, Some (t', arg_values))
    | `Path v, (NSlash, t') :: _ when String.equal "" v ->
      (false, matched_tok_count, Some (t', arg_values))
    | `Path _, (NRest, t') :: _ ->
      let path =
        drop path_tokens matched_tok_count
        |> List.map (fun (`Path tok) -> tok)
        |> String.concat "/"
      in
      let rest_url =
        String.split_on_char '?' request_target |> fun l ->
        if List.length l > 1 then path ^ "?" ^ List.nth l 1 else path
      in
      ( true
      , matched_tok_count
      , Some (t', Arg_value (string_d, rest_url) :: arg_values) )
    | `Query (name, value), (NQuery_arg (name', arg), t') :: nodes -> (
      match arg.convert value with
      | Some v when String.equal name name' ->
        (false, matched_tok_count, Some (t', Arg_value (arg, v) :: arg_values))
      | _ -> match_request_path tok arg_values matched_tok_count nodes)
    | `Query (name1, value1), (NQuery_exact (name2, value2), t') :: _
      when String.equal name1 name2 && String.equal value1 value2 ->
      (false, matched_tok_count, Some (t', arg_values))
    | _, _ :: nodes -> match_request_path tok arg_values matched_tok_count nodes
  in
  let rec match_method = function
    | [] -> None
    | (NMethod method'', t) :: _ when Method.equal method' method'' ->
      try_match t [] request_target_tokens 0
    | _ :: nodes -> (match_method [@tailcall]) nodes
  in
  match_method t.routes

and exec_route_handler :
    type a b.
    #Request.server_request -> a -> (a, b) request_target * arg_value list -> b
    =
 fun req f -> function
  | Nil, [] -> f req
  | Rest, [ Arg_value (d, v) ] -> (
    match eq string_d.id d.id with
    | Some Eq -> f v req
    | None -> assert false)
  | Slash, [] -> f req
  | Exact (_, request_target), arg_values ->
    exec_route_handler req f (request_target, arg_values)
  | Query_exact (_, _, request_target), arg_values ->
    exec_route_handler req f (request_target, arg_values)
  | ( Arg ({ id; _ }, request_target)
    , Arg_value ({ id = id'; _ }, v) :: arg_values ) -> (
    match eq id id' with
    | Some Eq -> exec_route_handler req (f v) (request_target, arg_values)
    | None -> assert false)
  | ( Query_arg (_, { id; _ }, request_target)
    , Arg_value ({ id = id'; _ }, v) :: arg_values ) -> (
    match eq id id' with
    | Some Eq -> exec_route_handler req (f v) (request_target, arg_values)
    | None -> assert false)
  | _, _ -> assert false

(* Pretty Printers *)

let pp_request_target fmt request_target =
  let rec loop :
      type a b. bool -> Format.formatter -> (a, b) request_target -> unit =
   fun qmark_printed fmt request_target ->
    match request_target with
    | Nil -> Format.fprintf fmt "%!"
    | Rest -> Format.fprintf fmt "/**%!"
    | Slash -> Format.fprintf fmt "/%!"
    | Exact (exact, request_target) ->
      Format.fprintf fmt "/%s%a" exact (loop qmark_printed) request_target
    | Query_exact (name, value, request_target) ->
      if not qmark_printed then
        Format.fprintf fmt "?%s=%s%a" name value (loop true) request_target
      else
        Format.fprintf fmt "&%s=%s%a" name value (loop qmark_printed)
          request_target
    | Arg (arg, request_target) ->
      Format.fprintf fmt "/:%s%a" arg.name (loop qmark_printed) request_target
    | Query_arg (name, arg, request_target) ->
      if not qmark_printed then
        Format.fprintf fmt "?%s=:%s%a" name arg.name (loop true) request_target
      else
        Format.fprintf fmt "&%s=:%s%a" name arg.name (loop qmark_printed)
          request_target
  in
  loop false fmt request_target

let pp_node fmt node =
  match node with
  | NRest -> Format.fprintf fmt "/**"
  | NSlash -> Format.fprintf fmt "/"
  | NExact exact -> Format.fprintf fmt "/%s" exact
  | NQuery_exact (name, value) -> Format.fprintf fmt "%s=%s" name value
  | NArg arg -> Format.fprintf fmt "/:%s" arg.name
  | NQuery_arg (name, arg) -> Format.fprintf fmt "%s=:%s" name arg.name
  | NMethod method' -> Format.fprintf fmt "%a" Method.pp method'

let pp_route : Format.formatter -> 'b route -> unit =
 fun fmt (Route (method', request_target, _)) ->
  Format.fprintf fmt "%a%a" Method.pp method' pp_request_target request_target

let pp fmt t =
  let rec loop qmark_printed fmt t =
    let nodes = t.routes in
    let len = List.length nodes in
    Format.pp_print_list
      ~pp_sep:(if len > 1 then Format.pp_force_newline else fun _ () -> ())
      (fun fmt (node, t') ->
        Format.pp_open_vbox fmt 2;
        (match node with
        | NQuery_exact _ | NQuery_arg _ ->
          let qmark_printed =
            if not qmark_printed then (
              Format.fprintf fmt "?%a" pp_node node;
              true)
            else (
              Format.fprintf fmt "&%a" pp_node node;
              false)
          in
          (pp' qmark_printed) fmt t'
        | node ->
          Format.fprintf fmt "%a" pp_node node;
          (pp' qmark_printed) fmt t');
        Format.pp_close_box fmt ())
      fmt nodes
  and pp' qmark_printed fmt t' =
    if List.length t'.routes > 0 then (
      Format.pp_print_break fmt 0 0;
      (loop qmark_printed) fmt t')
  in
  loop false fmt t

(* Used by wtr/request_target ppx *)

module Private = struct
  let nil = Nil
  let rest = Rest
  let slash = Slash
  let exact s request_target = Exact (s, request_target)

  let query_exact name value request_target =
    Query_exact (name, value, request_target)

  let arg d request_target = Arg (d, request_target)
  let query_arg name d request_target = Query_arg (name, d, request_target)
  let int = int_d
  let int32 = int32_d
  let int64 = int64_d
  let float = float_d
  let string = string_d
  let bool = bool_d
end
