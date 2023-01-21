module Style exposing
    ( color
    , interline
    , spacing
    , textSize
    )

import Color exposing (Color)
import Color.Manipulate


color =
    { layout = colorLayout
    , primary = colorPrimary
    , primaryDark =
        colorPrimary
            |> Color.Manipulate.darken 0.5
    , highlight = colorHighlight
    , highlightDark =
        colorHighlight
            |> Color.Manipulate.darken 0.5
    , highlightLight =
        colorHighlight
            |> Color.Manipulate.lighten 0.4
            |> Color.Manipulate.desaturate 0.5
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


colorLayout =
    rgb 0x00 0x00 0x00


colorPrimary =
    rgb 0xFF 0x00 0xCC


colorHighlight =
    rgb 0x00 0xEB 0xFF


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
