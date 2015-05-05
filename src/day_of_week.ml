module Array   = Core_array
module Int     = Core_int
module List    = Core_list
module String  = Core_string
module Hashtbl = Core_hashtbl
module Sexp    = Core_sexp

let failwithf = Core_printf.failwithf

module T = struct
  type t =
    | Sun
    | Mon
    | Tue
    | Wed
    | Thu
    | Fri
    | Sat
  with bin_io, compare

  let hash = Hashtbl.hash

  let to_string t =
    match t with
    | Sun -> "SUN"
    | Mon -> "MON"
    | Tue -> "TUE"
    | Wed -> "WED"
    | Thu -> "THU"
    | Fri -> "FRI"
    | Sat -> "SAT"
  ;;

  let of_string_internal s =
    match String.uppercase s with
    | "SUN" -> Sun
    | "MON" -> Mon
    | "TUE" -> Tue
    | "WED" -> Wed
    | "THU" -> Thu
    | "FRI" -> Fri
    | "SAT" -> Sat
    | _     -> failwithf "Day_of_week.of_string: %S" s ()
  ;;

  let of_int_exn i =
    match i with
    | 0 -> Sun
    | 1 -> Mon
    | 2 -> Tue
    | 3 -> Wed
    | 4 -> Thu
    | 5 -> Fri
    | 6 -> Sat
    | _ -> failwithf "Day_of_week.of_int_exn: %d" i ()
  ;;

  (* Be very generous with of_string.  We accept all possible capitalizations and the
     integer representations as well. *)
  let of_string s =
    try
      of_string_internal s
    with
    | _ ->
      try
        of_int_exn (Int.of_string s)
      with
      | _ -> failwithf "Day_of_week.of_string: %S" s ()
  ;;

  (* this is in T rather than outside so that the later functor application to build maps
     uses this sexp representation *)
  include Sexpable.Of_stringable (struct
    type nonrec t = t
    let of_string = of_string
    let to_string = to_string
  end)
end
include T

let weekdays = [ Mon; Tue; Wed; Thu; Fri ]

let weekends = [ Sat; Sun ]

(* written out to save overhead when loading modules.  The members of the set and the
   ordering should never change, so speed wins over something more complex that proves
   the order = the order in t at runtime *)
let all = [ Sun; Mon; Tue; Wed; Thu; Fri; Sat ]

TEST = List.is_sorted all ~compare

let of_int i = try Some (of_int_exn i) with _ -> None

let to_int t =
  match t with
  | Sun -> 0
  | Mon -> 1
  | Tue -> 2
  | Wed -> 3
  | Thu -> 4
  | Fri -> 5
  | Sat -> 6
;;

let iso_8601_weekday_number t =
  match t with
  | Mon -> 1
  | Tue -> 2
  | Wed -> 3
  | Thu -> 4
  | Fri -> 5
  | Sat -> 6
  | Sun -> 7
;;

let num_days_in_week = 7

let shift t i = of_int_exn (Int.( % ) (to_int t + i) num_days_in_week)

let num_days ~from ~to_ =
  let d = to_int to_ - to_int from in
  if Int.(d < 0) then d + num_days_in_week else d
;;

TEST = num_days ~from:Mon ~to_:Tue = 1;;
TEST = num_days ~from:Tue ~to_:Mon = 6;;
TEST "num_days is inverse to shift" =
  let all_days = [Sun; Mon; Tue; Wed; Thu; Fri; Sat] in
  List.for_all (List.cartesian_product all_days all_days)
    ~f:(fun (from, to_) ->
      let i = num_days ~from ~to_ in
      0 <= i && i < num_days_in_week && shift from i = to_)
;;

let is_sun_or_sat t = t = Sun || t = Sat

include Comparable.Make_binable (T)
include Hashable.Make_binable (T)

module Stable = struct
  module V1 = struct
    include T
  end

  TEST_MODULE "Day_of_week.V1" = Stable_unit_test.Make (struct
    include V1

    let equal = equal

    let tests =
      [ Sun, "SUN", "\000"
      ; Mon, "MON", "\001"
      ; Tue, "TUE", "\002"
      ; Wed, "WED", "\003"
      ; Thu, "THU", "\004"
      ; Fri, "FRI", "\005"
      ; Sat, "SAT", "\006"
      ]
  end)
end