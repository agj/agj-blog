module View.Figure exposing
    ( Figure
    , figure
    , view
    )

import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Style


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



-- VIEW


view : Figure msg -> Ui.Element msg
view (Figure config) =
    Ui.el
        [ Ui.varPadding Style.spacingVar.size2
        , UiBackground.color (Color.toElmUi Style.color.secondary10)
        , Ui.centerX
        ]
        config.content
