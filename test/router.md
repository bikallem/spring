# Router tests

```ocaml
open Router_test
open Spring

let () = Printexc.record_backtrace true
let test_get uri = Router.match' (make_request Method.get uri) router
let test_head uri = Router.match' (make_request Method.head uri) router
let test_post uri = Router.match' (make_request Method.post uri) router
let test_delete uri = Router.match' (make_request Method.delete uri) router

let fmt = Format.std_formatter
```

```ocaml
# test_get "/public/css/style.css";;
- : string option = Some "file path: css/style.css"

# test_get "/public/js/prog.js";;
- : string option = Some "file path: js/prog.js"

# test_get "/public/images/image1.jpg";;
- : string option = Some "file path: images/image1.jpg"

# test_get "/public/";;
- : string option = Some "file path: "

# test_get "/home/100001.1/";
- : string option = Some "Float page. number : 100001.100000"

# test_post "/home/100001.1";;
- : string option = None

# test_head "/home/100001/";;
- : string option = Some "Product Page. Product Id : 100001"

# test_post "/home/about";;
- : string option = None

# test_get "/home/about/1";;
- : string option = Some "about_page - 1"

# test_post "/home/about/3";;
- : string option = Some "about_page - 3"

# test_head "/home/about/3";;
- : string option = None

# test_delete "/home/about/3";;
- : string option = None

# test_get "/contact/bikal/123456";;
- : string option = Some "Contact page. Hi, bikal. Number 123456"

# test_post "/home/products/asdfasdf?a=1&b=2";;
- : string option = Some "full rest page: asdfasdf?a=1&b=2"

# test_post "/home/products/product1/locate";;
- : string option = Some "full rest page: product1/locate"

# test_get "/home/product1/";;
- : string option = Some "Wildcard page. product1. Remaining url: "

# test_get "/contact/bikal/true";;
- : string option = Some "Contact Page2. Name - bikal, number - true"

# test_get "/contact/bob/false";;
- : string option = Some "Contact Page2. Name - bob, number - false"

# test_post "/product/dyson350?section=233&q=true";;
- : string option =
Some "Product detail - dyson350. Section: 233. Display questions? true"

# test_post "/product/dyson350?section=2&q=false";;
- : string option =
Some "Product detail - dyson350. Section: 2. Display questions? false"

# test_get "/product/dyson350?section=2&q1=no";;
- : string option = None

# test_get "/product/dyson350?section=2&q1=yes";;
- : string option = Some "Product detail 2 - dyson350. Section: 2."

# test_get "/product/dyson350/section/2/q1/yes";;
- : string option = None

# test_get  "/fruit/apple";;
- : string option = Some "Apples are juicy!"

# test_get "/fruit/pineapple";;
- : string option = Some "Pineapple has scaly skin"

# test_get "/fruit/orange";;
- : string option = Some "Orange is a citrus fruit."

# test_get "/fruit/guava";;
- : string option = None

# test_get "/";
- : string option = Some "Root page"

# test_get "";;
- : string option = None

# test_head "/numbers/23/code/6888/";;
- : string option = Some "int32: 23, int64: 6888."

# test_head "/numbers/23.01/code/6888/";;
- : string option = None

# test_head "/numbers/23/code/6888.222/";;
- : string option = None
```

## Router.pp_route

```ocaml
# Router.pp_route fmt route1;; 
GET/home/about/:bool?h=:int&b=:bool&e=hello
- : unit = ()

# Router.pp_route fmt route2;;
POST/home/about/:int/:string/:Fruit
- : unit = ()

# Router.pp_route fmt route3;;
HEAD/home/:int/:int32/:int64/:Fruit?q1=hello&f=:Fruit&b=:bool&f=:float
- : unit = ()
```

## Router.pp

```ocaml
# Format.fprintf fmt "%a%!" Router.pp router;;
GET
  /home
    /about
      /:int
    /:float
      /
    /:string
      /**
  /contact
    /:string
      /:int
      /:bool
  /product
    /:string
      ?section=:int
        &q1=yes
      ?section=:string
        &q1=yes
  /fruit
    /:Fruit
  /
  /public
    /**
POST
  /home
    /about
      /:int
    /products
      /**
  /product
    /:string
      ?section=:int
        &q=:bool
HEAD
  /home
    /:int
      /
  /numbers
    /:int32
      /code
        /:int64
          /
DELETE
  /home
    /:int
      /
- : unit = ()
```

## Router.match' - match the top 1 first if more than one route is matched

```ocaml
# Router_test.top_1_first () ;;
- : string option = Some "Float: 12.000000"

# Router_test.top_1_first_2 ();;
- : string option = Some "Int  : 12"
```

## Router.match' - longest match wins if more than one route is matched

```ocaml
# Router_test.longest_match ();;
- : string option = Some "longest: 12"
```
