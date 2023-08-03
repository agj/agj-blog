module Custom.Element exposing (..)

import Element as Ui
import Html.Attributes


{-| Sets `aria-hidden` on the element.
-}
hiddenToScreenReaders : Ui.Attribute msg
hiddenToScreenReaders =
    Html.Attributes.attribute "aria-hidden" "true"
        |> Ui.htmlAttribute


nonSelectable : Ui.Attribute msg
nonSelectable =
    Html.Attributes.style "user-select" "none"
        |> Ui.htmlAttribute


id : String -> Ui.Attribute msg
id id_ =
    Html.Attributes.id id_
        |> Ui.htmlAttribute
