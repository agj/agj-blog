module View.Inline exposing
    ( setCode
    , setLink
    )

import Html exposing (Html)
import Html.Attributes exposing (class)
import Html.Events
import Sand
import Style


setCode : String -> Html msg
setCode code =
    [ Html.text code ]
        |> Html.span
            [ class "whitespace-pre-wrap rounded box-decoration-clone px-2 font-mono"
            , Sand.backgroundColor Style.color.layout05
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
