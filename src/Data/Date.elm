module Data.Date exposing
    ( formatShortDate
    , intToMonth
    , intToMonthFullName
    , wordpressToPosix
    )

import Dict exposing (Dict)
import Parser exposing ((|.), (|=), Parser)
import Time
import Time.Extra


formatShortDate : String -> Int -> Int -> String
formatShortDate year month date =
    "{year}, {month} {date}"
        |> String.replace "{year}" year
        |> String.replace "{month}" (intToMonthShortName month)
        |> String.replace "{date}" (String.fromInt date)


intToMonthFullName : Int -> String
intToMonthFullName num =
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


wordpressToPosix : String -> Maybe Time.Posix
wordpressToPosix wordpressDate =
    Parser.run wordpressToPosixParser wordpressDate
        |> Result.toMaybe


intToMonth : Int -> Time.Month
intToMonth int =
    Dict.get int intToMonthDict
        |> Maybe.map .t
        |> Maybe.withDefault Time.Jan



-- INTERNAL


wordpressToPosixParser : Parser Time.Posix
wordpressToPosixParser =
    Parser.succeed
        (\y mon d h min s ->
            Time.Extra.partsToPosix
                Time.utc
                { year = y
                , month = intToMonth mon
                , day = d
                , hour = h
                , minute = min
                , second = s
                , millisecond = 0
                }
        )
        |= Parser.int
        |. Parser.symbol "-"
        |= Parser.int
        |. Parser.symbol "-"
        |= Parser.int
        |. Parser.symbol " "
        |= Parser.int
        |. Parser.symbol ":"
        |= Parser.int
        |. Parser.symbol ":"
        |= Parser.int


intToMonthDict : Dict Int { t : Time.Month, long : String, short : String }
intToMonthDict =
    Dict.fromList
        [ ( 1, { t = Time.Jan, long = "January", short = "Jan." } )
        , ( 2, { t = Time.Feb, long = "February", short = "Feb." } )
        , ( 3, { t = Time.Mar, long = "March", short = "Mar." } )
        , ( 4, { t = Time.Apr, long = "April", short = "Apr." } )
        , ( 5, { t = Time.May, long = "May", short = "May." } )
        , ( 6, { t = Time.Jun, long = "June", short = "Jun." } )
        , ( 7, { t = Time.Jul, long = "July", short = "Jul." } )
        , ( 8, { t = Time.Aug, long = "August", short = "Aug." } )
        , ( 9, { t = Time.Sep, long = "September", short = "Sep." } )
        , ( 10, { t = Time.Oct, long = "October", short = "Oct." } )
        , ( 11, { t = Time.Nov, long = "November", short = "Nov." } )
        , ( 12, { t = Time.Dec, long = "December", short = "Dec." } )
        ]


intToMonthShortName : Int -> String
intToMonthShortName int =
    Dict.get int intToMonthDict
        |> Maybe.map .short
        |> Maybe.withDefault "???"
