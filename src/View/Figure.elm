module View.Figure exposing
    ( Figure
    , figure
    , setCaption
    , view
    )

import Html exposing (Html)
import Sand
import Style


type Figure msg
    = Figure
        { content : Html msg
        , caption : Maybe String
        }


figure : Html msg -> Figure msg
figure content =
    Figure
        { content = content
        , caption = Nothing
        }


setCaption : String -> Figure msg -> Figure msg
setCaption caption (Figure config) =
    Figure { config | caption = Just caption }



-- VIEW


view : Figure msg -> Html msg
view (Figure config) =
    let
        content : Html msg
        content =
            Sand.div
                [ Sand.padding Sand.L4
                , Sand.backgroundColor Style.color.layout05
                ]
                [ config.content ]

        caption : List (Html msg)
        caption =
            case config.caption of
                Just text ->
                    [ Sand.div
                        [ Sand.paddingLeft Sand.L6
                        , Sand.paddingRight Sand.L6
                        , Sand.fontColor Style.color.layout20
                        , Sand.paddingTop Sand.L5
                        , Sand.textAlignCenter
                        ]
                        [ Html.p [] [ Html.text text ] ]
                    ]

                Nothing ->
                    []
    in
    Sand.div [ Sand.alightItemsCenter ]
        (List.concat [ [ content ], caption ])
