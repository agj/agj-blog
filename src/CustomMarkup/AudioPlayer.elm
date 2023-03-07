module CustomMarkup.AudioPlayer exposing
    ( AudioPlayer
    , renderer
    , toElmUi
    )

import CustomMarkup.AudioPlayer.Track exposing (Track)
import Element as Ui
import Icon
import Markdown.Html


type alias AudioPlayer =
    { title : String
    }


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


toElmUi : AudioPlayer -> List Track -> Ui.Element msg
toElmUi audioPlayer tracks =
    Ui.column []
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
