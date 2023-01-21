module Custom.Color exposing (..)

import Color exposing (Color)
import Element as Ui


toElmUi : Color -> Ui.Color
toElmUi color =
    Ui.fromRgb (Color.toRgba color)
