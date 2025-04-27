module Custom.Html.Attributes exposing
    ( ariaDescribedBy
    , none
    , popoverAuto
    , popoverTarget
    , roleTooltip
    )

import Html exposing (Attribute)
import Html.Attributes


ariaDescribedBy : List String -> Attribute msg
ariaDescribedBy elementIds =
    Html.Attributes.attribute "aria-describedby" (String.join " " elementIds)


roleTooltip : Attribute msg
roleTooltip =
    Html.Attributes.attribute "role" "tooltip"


popoverAuto : Attribute msg
popoverAuto =
    Html.Attributes.attribute "popover" "auto"


popoverTarget : String -> Attribute msg
popoverTarget targetElementId =
    Html.Attributes.attribute "popovertarget" targetElementId


none : Attribute msg
none =
    Html.Attributes.classList []
