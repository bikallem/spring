open Spring

module Fruit = struct
  type t = Apple | Orange | Pineapple

  let t : t Uri_router.arg =
    Uri_router.arg "Fruit" (function
      | "apple" -> Some Apple
      | "orange" -> Some Orange
      | "pineapple" -> Some Pineapple
      | _ -> None)
end

let fruit_page fruit (_req : #Request.server_request) =
  match fruit with
  | Fruit.Apple -> Printf.sprintf "Apples are juicy!"
  | Orange -> Printf.sprintf "Orange is a citrus fruit."
  | Pineapple -> Printf.sprintf "Pineapple has scaly skin"

let about_page i (_req : #Request.server_request) =
  Format.sprintf "about_page - %d" i

let full_rest_page url _req =
  Format.sprintf "full rest page: %s" @@ Uri_router.rest_to_string url

let home_int_page i (_req : #Request.server_request) =
  Printf.sprintf "Product Page. Product Id : %d" i

let home_float_page f _req = Printf.sprintf "Float page. number : %f" f

let wildcard_page s url _req =
  Printf.sprintf "Wildcard page. %s. Remaining url: %s" s
  @@ Uri_router.rest_to_string url

let numbers_page id code _req = Printf.sprintf "int32: %ld, int64: %Ld." id code
let root_page (_req : #Request.server_request) = "Root page"

let contact_page name number _req =
  Printf.sprintf "Contact page. Hi, %s. Number %i" name number

let contact_page2 name call_me_later _req =
  Printf.sprintf "Contact Page2. Name - %s, number - %b" name call_me_later

let product_page name section_id q _req =
  Printf.sprintf "Product detail - %s. Section: %d. Display questions? %b" name
    section_id q

let product_page2 name section_id _req =
  Printf.sprintf "Product detail 2 - %s. Section: %d." name section_id

let product_page3 name section_id _req =
  Printf.sprintf "Product detail 2 - %s. Section: %s." name section_id

let public url _req =
  Format.sprintf "file path: %s" @@ Uri_router.rest_to_string url

let router =
  Uri_router.(
    router
      [ route Method.get {%r| /home/about/:int |} about_page
      ; route Method.post {%r| /home/about/:int |} about_page
      ; route Method.head {%r| /home/:int/ |} home_int_page
      ; route Method.delete {%r| /home/:int/ |} home_int_page
      ; route Method.get {%r| /home/:float/ |} home_float_page
      ; route Method.get {%r| /contact/*/:int|} contact_page
      ; route Method.post {%r| /home/products/**|} full_rest_page
      ; route Method.get {%r| /home/*/** |} wildcard_page
      ; route Method.get {%r| /contact/:string/:bool|} contact_page2
      ; route Method.post {%r| /product/:string?section=:int&q=:bool |}
          product_page
      ; route Method.get {%r| /product/:string?section=:int&q1=yes |}
          product_page2
      ; route Method.get {%r| /product/:string?section=:string&q1=yes|}
          product_page3
      ; route Method.get {%r| /fruit/:Fruit|} fruit_page
      ; route Method.get {%r| / |} root_page
      ; route Method.get {%r| /public/** |} public
      ; route Method.head {%r| /numbers/:int32/code/:int64/ |} numbers_page
      ])

let pp_route r = List.hd r |> Uri_router.pp_route Format.std_formatter
let pp_match req = Uri_router.match' req router

let route1 =
  Uri_router.route Method.get {%r|/home/about/:bool?h=:int&b=:bool&e=hello|}
    (fun _ _ _ _ -> ())

let route2 =
  Uri_router.route Method.post {%r|/home/about/:int/:string/:Fruit|}
    (fun _ _ _ _ -> ())

let route3 =
  Uri_router.route Method.head
    {%r|/home/:int/:int32/:int64/:Fruit?q1=hello&f=:Fruit&b=:bool&f=:float |}
    (fun _ _ _ _ _ _ _ _ -> ())

let get = Method.get

let make_request meth resource : Request.server_request =
  let client_addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8080) in
  Request.server_request ~resource meth client_addr (Eio.Buf_read.of_string "")

let top_1_first () =
  Uri_router.(
    router
      [ route get {%r| /home/:float |} (fun f _req ->
            Format.sprintf "Float: %f" f)
      ; route get {%r| /home/:int |} (fun i _req ->
            Format.sprintf "Int  : %d" i)
      ])
  |> Uri_router.match' @@ make_request Method.get "/home/12"

let top_1_first_2 () =
  Uri_router.(
    router
      [ route get {%r| /home/:int |} (fun i _req ->
            Format.sprintf "Int  : %d" i)
      ; route get {%r| /home/:float |} (fun f _req ->
            Format.sprintf "Float: %f" f)
      ])
  |> Uri_router.match' @@ make_request Method.get "/home/12"

let longest_match () =
  Uri_router.(
    router
      [ route get {%r| /home/:int |} (fun i _req ->
            Format.sprintf "Int  : %d" i)
      ; route get {%r| /home/:int/:string |} (fun i _ _req ->
            Format.sprintf "longest: %i" i)
      ])
  |> Uri_router.match' @@ make_request Method.get "/home/12/hello"
