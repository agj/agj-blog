module Custom.Html.Attributes exposing
    ( ariaDescribedBy
    , none
    , popoverAuto
    , popoverTarget
    , roleTooltip
    , tabIndex
    )

import Html exposing (Attribute)
import Html.Attributes exposing (attribute)


ariaDescribedBy : List String -> Attribute msg
ariaDescribedBy elementIds =
    attribute "aria-describedby" (String.join " " elementIds)


roleTooltip : Attribute msg
roleTooltip =
    attribute "role" "tooltip"


popoverAuto : Attribute msg
popoverAuto =
    attribute "popover" "auto"


popoverTarget : String -> Attribute msg
popoverTarget targetElementId =
    attribute "popovertarget" targetElementId


none : Attribute msg
none =
    Html.Attributes.classList []


{-| Use `0` to make any element able to receive keyboard focus.
-}
tabIndex : Int -> Attribute msg
tabIndex index =
    attribute "tabindex" (String.fromInt index)
