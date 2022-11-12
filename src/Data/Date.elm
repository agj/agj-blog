module Data.Date exposing (..)


formatShortDate : String -> Int -> Int -> String
formatShortDate year month date =
    "{year}, {month} {date}"
        |> String.replace "{year}" year
        |> String.replace "{month}" (monthNumberToShortName month)
        |> String.replace "{date}" (String.fromInt date)


formatIso8601Date : String -> Int -> Int -> String
formatIso8601Date year month date =
    "{year}-{month}-{date}"
        |> String.replace "{year}" year
        |> String.replace "{month}" (String.fromInt month |> String.padLeft 2 '0')
        |> String.replace "{date}" (String.fromInt date)


monthNumberToShortName : Int -> String
monthNumberToShortName num =
    case num of
        1 ->
            "Jan."

        2 ->
            "Feb."

        3 ->
            "Mar."

        4 ->
            "Apr."

        5 ->
            "May."

        6 ->
            "Jun."

        7 ->
            "Jul."

        8 ->
            "Aug."

        9 ->
            "Sep."

        10 ->
            "Oct."

        11 ->
            "Nov."

        12 ->
            "Dec."

        _ ->
            "???"


monthNumberToFullName : Int -> String
monthNumberToFullName num =
    case num of
        1 ->
            "January"

        2 ->
            "February"

        3 ->
            "March"

        4 ->
            "April"

        5 ->
            "May"

        6 ->
            "June"

        7 ->
            "July"

        8 ->
            "August"

        9 ->
            "September"

        10 ->
            "October"

        11 ->
            "November"

        12 ->
            "December"

        _ ->
            "???"
