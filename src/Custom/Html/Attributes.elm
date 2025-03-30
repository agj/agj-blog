module Custom.Html.Attributes exposing (ariaDescribedBy, none, roleTooltip)

import Html exposing (Attribute)
import Html.Attributes


ariaDescribedBy : List String -> Attribute msg
ariaDescribedBy elementIds =
    Html.Attributes.attribute "aria-describedby" (String.join " " elementIds)


roleTooltip : Attribute msg
roleTooltip =
    Html.Attributes.attribute "role" "tooltip"


none : Attribute msg
none =
    Html.Attributes.classList []
