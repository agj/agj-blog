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
    , secondary = colorSecondary
    , secondaryDark =
        colorSecondary
            |> Color.Manipulate.darken 0.5
    , secondaryLight =
        colorSecondary
            |> Color.Manipulate.lighten 0.4
            |> Color.Manipulate.desaturate 0.5
    , layout50 = colorLayout
    , layout40 =
        colorLayout
            |> Color.Manipulate.lighten 0.2
    , layout30 =
        colorLayout
            |> Color.Manipulate.lighten 0.4
    , layout20 =
        colorLayout
            |> Color.Manipulate.lighten 0.6
    , layout10 =
        colorLayout
            |> Color.Manipulate.lighten 0.8
    , layout05 =
        colorLayout
            |> Color.Manipulate.lighten 0.9
    , primary50 = colorPrimary
    , primary40 =
        colorPrimary
            |> Color.Manipulate.lighten 0.2
    , primary30 =
        colorPrimary
            |> Color.Manipulate.lighten 0.4
    , primary20 =
        colorPrimary
            |> Color.Manipulate.lighten 0.6
    , primary10 =
        colorPrimary
            |> Color.Manipulate.lighten 0.8
    , primary05 =
        colorPrimary
            |> Color.Manipulate.lighten 0.9
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


colorSecondary =
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
