module View.Inline exposing
    ( setCode
    , setLink
    )

import Html exposing (Html)
import Html.Attributes exposing (class)
import Html.Events


setCode : String -> Html msg
setCode code =
    Html.span [ class "bg-layout-05 whitespace-pre-wrap rounded box-decoration-clone px-2 font-mono" ]
        [ Html.text code ]


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
    Html.a (attrs ++ [ Html.Attributes.href destination ])
        children
