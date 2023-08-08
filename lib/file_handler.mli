val handle_get :
     on_error:(exn -> Response.server Response.t)
  -> _ Eio.Path.t
  -> Request.server Request.t
  -> Response.server Response.t
