module CustomMarkup.AudioPlayer exposing
    ( AudioPlayer
    , Config
    , State
    , initialState
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
    { onStateUpdated : State -> msg
    }


type State
    = Stopped
    | Playing Track
    | Paused Track


type TrackStatus
    = PlayingTrack
    | PausedTrack
    | InactiveTrack


initialState : State
initialState =
    Stopped


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


toElmUi : State -> Config msg -> AudioPlayer -> List Track -> Ui.Element msg
toElmUi state config audioPlayer tracks =
    Ui.column
        [ UiBackground.color (Style.color.layout05 |> Color.toElmUi)
        ]
        [ Ui.text audioPlayer.title
        , Ui.column []
            (tracks
                |> List.map
                    (\track ->
                        trackToElmUi
                            config
                            (getTrackStatus state track)
                            track
                    )
            )
        ]



-- INTERNAL


trackToElmUi : Config msg -> TrackStatus -> Track -> Ui.Element msg
trackToElmUi config status track =
    let
        icon =
            case status of
                PlayingTrack ->
                    Icon.pause

                PausedTrack ->
                    Icon.play

                InactiveTrack ->
                    Icon.none
    in
    UiInput.button
        [ UiBorder.rounded 0
        , UiBackground.color (Style.color.transparent |> Color.toElmUi)
        , Ui.width Ui.fill
        ]
        { onPress = Just (config.onStateUpdated (Playing track))
        , label =
            Ui.row []
                [ icon Icon.Medium
                , Ui.text track.title
                ]
        }


getTrackStatus : State -> Track -> TrackStatus
getTrackStatus state track =
    case state of
        Playing playingTrack ->
            if playingTrack == track then
                PlayingTrack

            else
                InactiveTrack

        Paused pausedTrack ->
            if pausedTrack == track then
                PausedTrack

            else
                InactiveTrack

        Stopped ->
            InactiveTrack
