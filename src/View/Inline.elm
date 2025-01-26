module View.Inline exposing
    ( setCode
    , setLink
    )

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Background as UiBackground
import Element.Events as UiEvents
import Element.Font as UiFont
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Sand
import Style


setCode : String -> Html msg
setCode code =
    [ Html.text code ]
        |> Html.span
            [ Html.Attributes.style "white-space" "pre-wrap"
            , Html.Attributes.style "font-family" "monospace"
            , Sand.fontSize Sand.TextM
            , Sand.backgroundColor Style.color.layout05
            , Sand.paddingLeft Sand.L2
            , Sand.paddingRight Sand.L2
            , Sand.borderRadius Sand.L2
            , Html.Attributes.style "box-decoration-break" "clone"
            ]


setLink : Maybe (String -> msg) -> String -> List (Html msg) -> Html msg
setLink onClickMaybe destination children =
    let
        attrs =
            case onClickMaybe of
                Just onClick ->
                    [ Html.Events.onClick (onClick destination) ]

                Nothing ->
                    []
    in
    Html.a
        (attrs
            ++ [ Html.Attributes.href destination
               , Sand.fontColor Style.color.primary70
               ]
        )
        children
