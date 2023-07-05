type t = string * string

let host = ("__Host-", "__host-")

let host_len = String.length @@ fst host

let secure = ("__Secure-", "__secure-")

let secure_len = String.length @@ fst secure

let contains_prefix ?(case_sensitive = true) name (t, t_lowercase) =
  let name', t' =
    if case_sensitive then (name, t)
    else (String.Ascii.lowercase name, t_lowercase)
  in
  String.is_prefix ~affix:t' name'

let cut_prefix ?case_sensitive name =
  let name', t' =
    if contains_prefix ?case_sensitive name host then
      (String.with_range ~first:host_len name, Some host)
    else if contains_prefix ?case_sensitive name secure then
      (String.with_range ~first:secure_len name, Some secure)
    else (name, None)
  in
  (name', t')

let to_string (t, _) = t

let compare (t0, _) (t1, _) = String.compare t0 t1

let equal (t0, _) (t1, _) = String.equal t0 t1

let pp fmt (t, _) = Format.fprintf fmt "%s" t
