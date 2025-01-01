module View.Figure exposing
    ( Figure
    , figure
    , setCaption
    , view
    )

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Background as UiBackground
import Element.Font as UiFont
import Style
import View.Paragraph


type Figure msg
    = Figure
        { content : Ui.Element msg
        , caption : Maybe String
        }


figure : Ui.Element msg -> Figure msg
figure content =
    Figure
        { content = content
        , caption = Nothing
        }


setCaption : String -> Figure msg -> Figure msg
setCaption caption (Figure config) =
    Figure { config | caption = Just caption }



-- VIEW


view : Figure msg -> Ui.Element msg
view (Figure config) =
    let
        content =
            Ui.el
                [ Ui.varPadding Style.spacing.size2
                , UiBackground.color (Color.toElmUi Style.color.secondary10)
                , Ui.centerX
                ]
                config.content

        caption =
            case config.caption of
                Just text ->
                    [ Ui.el
                        [ Ui.varPaddingLeft Style.spacing.size9
                        , Ui.varPaddingRight Style.spacing.size9
                        , UiFont.color (Color.toElmUi Style.color.layout20)
                        , Ui.varPaddingTop Style.spacing.size3
                        ]
                        (View.Paragraph.view [ Ui.text text ])
                    ]

                Nothing ->
                    []
    in
    Ui.column [ Ui.centerX ]
        (List.concat [ [ content ], caption ])
