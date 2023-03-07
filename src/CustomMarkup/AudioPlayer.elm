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
import Element.Input as UiInput
import Icon
import Markdown.Html
import Style


type alias AudioPlayer =
    { title : String
    }


type alias Config msg =
    { playingTrack : Maybe Track
    , onStopTrack : Maybe msg
    , onPlayPauseTrack : Maybe msg
    }


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


toElmUi : Config msg -> AudioPlayer -> List Track -> Ui.Element msg
toElmUi config audioPlayer tracks =
    Ui.column
        [ UiBackground.color (Style.color.layout05 |> Color.toElmUi)
        ]
        [ Ui.text audioPlayer.title
        , Ui.column []
            (tracks
                |> List.map (trackToElmUi config)
            )
        ]



-- INTERNAL


trackToElmUi : Config msg -> Track -> Ui.Element msg
trackToElmUi config track =
    UiInput.button
        [ UiBorder.rounded 0
        , UiBackground.color (Style.color.transparent |> Color.toElmUi)
        , Ui.width Ui.fill
        ]
        { onPress = Nothing
        , label =
            Ui.row []
                [ Icon.none Icon.Medium
                , Ui.text track.title
                ]
        }
