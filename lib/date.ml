type state =
  { i : string (* input *)
  ; mutable pos : int
  }

let accept s n = s.pos <- s.pos + n

let day_name s =
  let v = String.with_range ~first:s.pos ~len:3 s.i in
  (match v with
  | "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun" -> ()
  | x -> failwith @@ "day_name : unrecognized day name '" ^ x ^ "'");
  accept s 3

let digit n s =
  let v = String.with_range ~first:s.pos ~len:n s.i in
  if
    String.for_all
      (function
        | '0' .. '9' -> true
        | _ -> false)
      v
  then (
    accept s n;
    int_of_string v)
  else failwith @@ "digit: unrecognized integer '" ^ v ^ "'"

let comma s =
  match String.get s.i s.pos with
  | ',' -> accept s 1
  | ch -> failwith @@ "comma: expected ',', got '" ^ Char.escaped ch ^ "'"

let space s =
  match String.get s.i s.pos with
  | ' ' -> accept s 1
  | x -> failwith @@ "space: expected ' '(space), got '" ^ Char.escaped x ^ "'"

let day_l s =
  [ "Monday"
  ; "Tuesday"
  ; "Wednesday"
  ; "Thursday"
  ; "Friday"
  ; "Saturday"
  ; "Sunday"
  ]
  |> List.find_opt (fun v ->
         let v1 = String.with_range ~first:s.pos ~len:(String.length v) s.i in
         String.equal v v1)
  |> function
  | Some v -> accept s (String.length v)
  | None -> failwith "day_l : expected long day name"

let month s =
  let v = String.with_range ~first:s.pos ~len:3 s.i in
  List.find_opt
    (fun (v1, _) -> String.equal v v1)
    [ ("Jan", 1)
    ; ("Feb", 2)
    ; ("Mar", 3)
    ; ("Apr", 4)
    ; ("May", 5)
    ; ("Jun", 6)
    ; ("Jul", 7)
    ; ("Aug", 8)
    ; ("Sep", 9)
    ; ("Oct", 10)
    ; ("Nov", 11)
    ; ("Dec", 12)
    ]
  |> function
  | Some (v, m) ->
    accept s (String.length v);
    m
  | None -> failwith "month: expected month"

let gmt s =
  let v = String.with_range ~first:s.pos ~len:3 s.i in
  if String.equal "GMT" v then accept s 3 else failwith "gmt: expected GMT"

let date1 s =
  let d = digit 2 s in
  space s;
  let m = month s in
  space s;
  let y = digit 4 s in
  (y, m, d)

let colon s =
  match String.get s.i s.pos with
  | ':' -> accept s 1
  | ch -> failwith @@ "colon: expected ':', got '" ^ Char.escaped ch ^ "'"

let time_of_day s =
  let hour = digit 2 s in
  colon s;
  let minute = digit 2 s in
  colon s;
  let second = digit 2 s in
  (hour, minute, second)

let fix_date s =
  day_name s;
  comma s;
  space s;
  let date1 = date1 s in
  space s;
  let tod = time_of_day s in
  space s;
  gmt s;
  (date1, tod)

let dash s =
  match String.get s.i s.pos with
  | '-' -> accept s 1
  | ch -> failwith @@ "dash: expected '-', got '" ^ Char.escaped ch ^ "'"

let date2 s =
  let d = digit 2 s in
  dash s;
  let m = month s in
  dash s;
  let y = digit 2 s in
  let y = if y >= 50 then 1900 + y else 2000 + y in
  (y, m, d)

let rfc850_date s =
  day_l s;
  comma s;
  space s;
  let date2 = date2 s in
  space s;
  let tod = time_of_day s in
  space s;
  gmt s;
  (date2, tod)

let date3 s =
  let m = month s in
  space s;
  let day =
    match String.get s.i s.pos with
    | ('0' .. '9' | ' ') as c1 ->
      let d =
        match String.get s.i (s.pos + 1) with
        | '0' .. '9' as c2 ->
          Char.escaped c1 ^ Char.escaped c2 |> String.trim |> int_of_string
        | _ -> int_of_string (Char.escaped c1)
      in
      accept s 2;
      d
    | x -> failwith @@ "date3: expected digit, got '" ^ Char.escaped x ^ "'"
  in
  (m, day)

let asctime_date s =
  day_name s;
  space s;
  let m, d = date3 s in
  Eio.traceln "m:%d, d:%d" m d;
  space s;
  let tod = time_of_day s in
  space s;
  Eio.traceln "y";
  let y = digit 4 s in
  ((y, m, d), tod)

let decode v =
  let s = { i = v; pos = 0 } in
  let date, time =
    try fix_date s
    with _ -> (
      s.pos <- 0;
      try rfc850_date s
      with _ ->
        s.pos <- 0;
        asctime_date s)
  in
  Ptime.of_date_time (date, (time, 0)) |> Option.get

let encode now =
  let (year, mm, dd), ((hh, min, ss), _) = Ptime.to_date_time now in
  let weekday = Ptime.weekday now in
  let weekday =
    match weekday with
    | `Mon -> "Mon"
    | `Tue -> "Tue"
    | `Wed -> "Wed"
    | `Thu -> "Thu"
    | `Fri -> "Fri"
    | `Sat -> "Sat"
    | `Sun -> "Sun"
  in
  let month =
    match mm with
    | 1 -> "Jan"
    | 2 -> "Feb"
    | 3 -> "Mar"
    | 4 -> "Apr"
    | 5 -> "May"
    | 6 -> "Jun"
    | 7 -> "Jul"
    | 8 -> "Aug"
    | 9 -> "Sep"
    | 10 -> "Oct"
    | 11 -> "Nov"
    | 12 -> "Dec"
    | _ -> failwith "Invalid HTTP datetime value"
  in
  Format.sprintf "%s, %02d %s %04d %02d:%02d:%02d GMT" weekday dd month year hh
    min ss
