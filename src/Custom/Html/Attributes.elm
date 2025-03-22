module Custom.Html.Attributes exposing (none)

import Html exposing (Attribute)
import Html.Attributes


none : Attribute msg
none =
    Html.Attributes.classList []
