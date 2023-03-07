module CustomMarkup.AudioPlayer exposing
    ( AudioPlayer
    , renderer
    , toElmUi
    )

import Custom.Color as Color
import CustomMarkup.AudioPlayer.Track exposing (Track)
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Icon
import Markdown.Html
import Style


type alias AudioPlayer =
    { title : String
    }


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


toElmUi : AudioPlayer -> List Track -> Ui.Element msg
toElmUi audioPlayer tracks =
    Ui.column
        [ UiBackground.color (Style.color.layout05 |> Color.toElmUi)
        ]
        [ Ui.text audioPlayer.title
        , Ui.column []
            (tracks
                |> List.map trackToElmUi
            )
        ]



-- INTERNAL


trackToElmUi : Track -> Ui.Element msg
trackToElmUi track =
    Ui.row []
        [ Icon.play Icon.Medium
        , Ui.text track.title
        ]
