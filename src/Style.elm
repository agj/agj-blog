module Style exposing
    ( blockPadding
    , color
    , interblock
    , interline
    , padding
    , spacing
    , spacingVar
    , textSize
    , textSizeMonospace
    )

import Color exposing (Color)
import Color.Manipulate
import Css


color =
    { layout = colorLayout
    , layout50 = colorLayout
    , layout40 = colorLayout |> lighten 0.2
    , layout30 = colorLayout |> lighten 0.4
    , layout20 = colorLayout |> lighten 0.6
    , layout10 = colorLayout |> lighten 0.8
    , layout05 = colorLayout |> lighten 0.9
    , primary50 = colorPrimary
    , primary40 = colorPrimary |> lighten 0.2
    , primary30 = colorPrimary |> lighten 0.4
    , primary20 = colorPrimary |> lighten 0.6
    , primary10 = colorPrimary |> lighten 0.8
    , primary05 = colorPrimary |> lighten 0.9
    , secondary90 = colorSecondary |> darken 0.8
    , secondary80 = colorSecondary |> darken 0.6
    , secondary70 = colorSecondary |> darken 0.4
    , secondary60 = colorSecondary |> darken 0.2
    , secondary50 = colorSecondary
    , secondary40 = colorSecondary |> lighten 0.2
    , secondary30 = colorSecondary |> lighten 0.4
    , secondary20 = colorSecondary |> lighten 0.6
    , secondary10 = colorSecondary |> lighten 0.8
    , secondary05 = colorSecondary |> lighten 0.9
    , transparent = Color.rgba 1 1 1 0
    , white = Color.rgb 1 1 1
    }


spacing =
    { size1 = 3
    , size2 = 5
    , size3 = 8
    , size4 = 13
    , size5 = 21
    , size6 = 34
    , size7 = 55
    , size8 = 89
    , size9 = 144
    }


spacingVar =
    { size1 = Css.Var "spacing-1"
    , size2 = Css.Var "spacing-2"
    , size3 = Css.Var "spacing-3"
    , size4 = Css.Var "spacing-4"
    , size5 = Css.Var "spacing-5"
    , size6 = Css.Var "spacing-6"
    , size7 = Css.Var "spacing-7"
    , size8 = Css.Var "spacing-8"
    , size9 = Css.Var "spacing-9"
    }


padding =
    { left = 0
    , right = 0
    , top = 0
    , bottom = 0
    }



-- TYPOGRAPHY


colorLayout =
    rgb 0x00 0x00 0x00


colorPrimary =
    rgb 0xFF 0x00 0xCC


colorSecondary =
    rgb 0x00 0xEB 0xFF


textSize =
    { m = Css.Var "text-size-m"
    , l = Css.Var "text-size-l"
    , xl = Css.Var "text-size-xl"
    , xxl = Css.Var "text-size-xxl"
    }


textSizeMonospace =
    { m = Css.CalcMultiplication (Css.Unitless 0.9) textSize.m
    , l = Css.CalcMultiplication (Css.Unitless 0.9) textSize.l
    , xl = Css.CalcMultiplication (Css.Unitless 0.9) textSize.xl
    , xxl = Css.CalcMultiplication (Css.Unitless 0.9) textSize.xxl
    }


interline =
    { s = Css.CalcMultiplication (Css.Unitless 0.4)
    , m = Css.CalcMultiplication (Css.Unitless 0.6)
    }


blockPadding : Css.Expression -> (Css.Expression -> Css.Expression) -> Css.Expression
blockPadding textSize_ interline_ =
    Css.CalcMultiplication (interline_ textSize_) (Css.Unitless 0.5)


interblock =
    { zero = calculateInterblock 0
    , m = calculateInterblock spacing.size3
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


calculateInterblock : Int -> Int -> (Int -> Int) -> Int
calculateInterblock paddingToAdd textSize_ interline_ =
    round (toFloat (interline_ textSize_) / 2) + paddingToAdd


lighten : Float -> Color -> Color
lighten amount color_ =
    color_
        |> Color.Manipulate.scaleHsl
            { saturationScale = 0
            , lightnessScale = amount
            , alphaScale = 0
            }


darken : Float -> Color -> Color
darken amount =
    lighten -amount
