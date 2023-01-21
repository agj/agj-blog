module Style exposing
    ( color
    , interline
    , spacing
    , textSize
    )

import Color exposing (Color)


color =
    { main100 = rgb 0x14 0x16 0x1A
    , highlight50 = rgb 0x9F 0x1D 0x39
    }


spacing =
    { size1 = 4
    , size2 = 8
    , size3 = 16
    , size4 = 24
    , size5 = 32
    , size6 = 40
    , size7 = 48
    , size8 = 56
    , size9 = 64
    }



-- TYPOGRAPHY


textSize =
    { m = 18
    , l = 24
    , xl = 35
    , xxl = 60
    }


interline =
    { m = calculateInterline 0.6
    }



-- INTERNAL


rgb : Int -> Int -> Int -> Color
rgb red green blue =
    Color.rgb255 red green blue


calculateInterline : Float -> Int -> Int
calculateInterline factor textSize_ =
    toFloat textSize_
        * factor
        |> round
