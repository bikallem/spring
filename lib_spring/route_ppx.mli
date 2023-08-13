(** Routes ppx provides a ppx mehcanism to specify request routes for
    {!val:Router.t}.

    Routes can be specified as follows:

    + [[%r "route-syntax" ]] or
    + [{%r| route-syntax |}] - {i since OCaml 4.11.0}

    where [route-syntax] is a string which follows the grammar specified in
    {{!section:syntax} %r Syntax}.

    {2 Demo}

    {[
      let ppx_routers =
        [ {%r| /home/about/       |} about_page
        ; {%r| /home/:int/        |} prod_page
        ; {%r| /home/:float/      |} float_page
        ; {%r| /contact/*/:int                       |} contact_page
        ; {%r| /product/:string?section=:int&q=:bool |} product1
        ; {%r| /product/:string?section=:int&q1=yes  |} product2
        ; {%r| /fruit/:Fruit                         |} fruit_page
        ; {%r| /                                     |} root_page
        ; {%r| /faq/:int/**                          |} faq
        ]
    ]}

    {1:syntax %r Syntax}

    In general, the [%r] syntax closely mirrors that of a HTTP {i path}{^ 1} and
    {i query}{^ 2} syntax. The two notable points of divergence are as follows:

    + [%r] allows to specify HTTP methods applicable to a {i request target}
    + [%r] only allows [key=value] form of query specification.

    We use {i ABNF notation}{^ 3} to specify the [%r] syntax.

    {%html:
<pre><div class="code hljs abnf">
routes-syntax     = http-path ["?" http-query]
http-path         = "/" wtr-segment
wtr-segment       = wtr-arg / rest / wildcard / [segment-nz *( "/" segment)]
wtr-arg	          = ":int" / ":int32" / ":int64" / ":float" / ":bool" / ":string" / custom-arg
custom-arg        = ":" ocaml-module-path 

ocaml-module-path = module-name *("." module-name)      ; OCaml module path
ocaml-module-name = (A-Z) *( ALPHA / DIGIT / "_" / "'" )   ; OCaml module name

rest             = "**"
wildcard          = "*"
segment           = *pchar
segment-nz        = 1*pchar
pchar             = unreserved / pct-encoded / sub-delims / ":" / "@"
unreserved        = ALPHA / DIGIT / "-" / "." / "_" / "~"
pct-encoded       = "%" HEXDIG HEXDIG
sub-delims        = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="

http-query        = query-key-value *("&" query-key-value)
query-key-value   = query-name "=" query-value
query-value       = 1*pchar / wtr-arg
query-name        = 1( pchar / "/" / "?" )
qchar             = unreserved / pct-encoded / qsub-delims / ":" / "@"
qsub-delims       = "!" / "$" / "'" / "(" / ")" / "*" / "+" / "," / ";"

ALPHA             =  %x41-5A / %x61-7A   ; A-Z / a-z
DIGIT             =  %x30-39              ; 0-9
HEXDIG            =  DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
</code></pre>
%}

    {2 wtr-segment}

    - rest[(**)] is {!val:Wtr.rest}
    - wildcard[(\*\)] is {!val:Wtr.string}

    {2 wtr-arg}

    - [:int] - is {!val:Wtr.int} when used in path and {!val:Wtr.qint} when used
      in query
    - [:int32] - is {!val:Wtr.int32} when used in path and {!val:Wtr.qint32}
      when used in query
    - [:int64] - is {!val:Wtr.int64} when used in path and {!val:Wtr.qint64}
      when used in query
    - [:float] - is {!val:Wtr.float} when used in path and {!val:Wtr.qfloat}
      when used in query
    - [:bool] - is {!val:Wtr.bool} when used in path and {!val:Wtr.qbool} when
      used in query
    - [:string] - is {!val:Wtr.string} when used in path and {!val:Wtr.qstring}
      when used in query
    - [:custom-arg] - is the OCaml module name which implements the user defined
      {!type:Wtr.arg} value, e.g. [:Fruit] or [:LibA.Fruit]

    {1:references References}

    + {{:https://datatracker.ietf.org/doc/html/rfc3986#section-3.3} HTTP path}
    + {{:https://datatracker.ietf.org/doc/html/rfc3986#section-3.4} HtTP query}
    + {{:https://datatracker.ietf.org/doc/html/rfc5234#section-3.6} ABNF} *)
