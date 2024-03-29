type t = Ptime.t

open Buf_read.Syntax

let day_name =
  let+ dn = Buf_read.take 3 in
  match dn with
  | "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat" | "Sun" -> ()
  | x -> failwith @@ "day_name : unrecognized day name '" ^ x ^ "'"

let digit n =
  let+ v = Buf_read.take n in
  int_of_string v

let comma = Buf_read.char ','

let day_l =
  let+ day =
    Buf_read.take_while (function
      | 'a' .. 'z' | 'A' .. 'Z' -> true
      | _ -> false)
  in
  match day with
  | "Monday"
  | "Tuesday"
  | "Wednesday"
  | "Thursday"
  | "Friday"
  | "Saturday"
  | "Sunday" -> ()
  | _ -> failwith "day_l : expected long day name"

let month =
  let+ m = Buf_read.take 3 in
  match m with
  | "Jan" -> 1
  | "Feb" -> 2
  | "Mar" -> 3
  | "Apr" -> 4
  | "May" -> 5
  | "Jun" -> 6
  | "Jul" -> 7
  | "Aug" -> 8
  | "Sep" -> 9
  | "Oct" -> 10
  | "Nov" -> 11
  | "Dec" -> 12
  | _ -> failwith "month: expected month"

let gmt = Buf_read.string "GMT"

let space = Buf_read.space

let date1 =
  let* d = digit 2 <* space in
  let* m = month <* space in
  let+ y = digit 4 in
  (y, m, d)

let colon = Buf_read.char ':'

let time_of_day =
  let* hour = digit 2 <* colon in
  let* minute = digit 2 <* colon in
  let+ second = digit 2 in
  (hour, minute, second)

let fix_date =
  let* date1 = day_name *> comma *> space *> date1 <* space in
  let+ tod = time_of_day <* space <* gmt in
  (date1, tod)

let dash = Buf_read.char '-'

let date2 =
  let* d = digit 2 <* dash in
  let* m = month <* dash in
  let+ y = digit 2 in
  let y = if y >= 50 then 1900 + y else 2000 + y in
  (y, m, d)

let rfc850_date =
  let* date2 = day_l *> comma *> space *> date2 <* space in
  let+ tod = time_of_day <* space <* gmt in
  (date2, tod)

let date3 =
  let* m = month <* space in
  let+ day =
    let+ s = Buf_read.take 2 in
    let buf =
      String.fold_left
        (fun buf c ->
          match c with
          | '0' .. '9' ->
            Buffer.add_char buf c;
            buf
          | ' ' -> buf
          | _ -> failwith "Invalid date3 value")
        (Buffer.create 2) s
    in
    int_of_string (Buffer.contents buf)
  in
  (m, day)

let asctime_date =
  let* m, d = day_name *> space *> date3 <* space in
  let* tod = time_of_day <* space in
  let+ y = digit 4 in
  ((y, m, d), tod)

let of_ptime ptime = Ptime.truncate ~frac_s:0 ptime

let of_float_s d = Float.trunc d |> Ptime.of_float_s

let decode v =
  let r () = Buf_read.of_string v in
  let date, time =
    try fix_date @@ r ()
    with _ -> ( try rfc850_date @@ r () with _ -> asctime_date @@ r ())
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

let now (clock : #Eio.Time.clock) =
  let now = Eio.Time.now clock in
  of_float_s now |> Option.get

let compare = Ptime.compare

let equal = Ptime.equal

let is_later = Ptime.is_later

let is_earlier = Ptime.is_earlier

let pp fmt t = Format.fprintf fmt "%s" @@ encode t
