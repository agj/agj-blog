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
import Element.Font as UiFont
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
    case tracks of
        firstTrack :: _ ->
            Ui.column
                [ UiBackground.color (Style.color.layout05 |> Color.toElmUi)
                ]
                [ titleToElmUi state config firstTrack audioPlayer.title
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

        [] ->
            Ui.none



-- INTERNAL


titleToElmUi : State -> Config msg -> Track -> String -> Ui.Element msg
titleToElmUi state config firstTrack title =
    let
        ( newStateOnPress, icon ) =
            case state of
                Playing _ ->
                    ( Stopped
                    , Icon.stop
                    )

                Paused _ ->
                    ( Stopped
                    , Icon.stop
                    )

                Stopped ->
                    ( Playing firstTrack
                    , Icon.play
                    )
    in
    UiInput.button
        [ UiBorder.rounded 0
        , UiBackground.color (Style.color.layout40 |> Color.toElmUi)
        , UiFont.color (Style.color.white |> Color.toElmUi)
        , Ui.width Ui.fill
        , Ui.paddingXY Style.spacing.size3 Style.spacing.size2
        ]
        { onPress = Just (config.onStateUpdated newStateOnPress)
        , label =
            Ui.row
                [ Ui.spacing Style.spacing.size1
                ]
                [ icon Icon.Medium
                , Ui.text title
                ]
        }


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

        ( fontColor, backgroundColor ) =
            case status of
                PlayingTrack ->
                    ( Style.color.white
                    , Style.color.secondary50
                    )

                PausedTrack ->
                    ( Style.color.white
                    , Style.color.secondary50
                    )

                InactiveTrack ->
                    ( Style.color.layout50
                    , Style.color.transparent
                    )

        newStateOnPress =
            case status of
                PlayingTrack ->
                    Paused track

                PausedTrack ->
                    Playing track

                InactiveTrack ->
                    Playing track
    in
    UiInput.button
        [ UiBorder.rounded 0
        , UiBackground.color (backgroundColor |> Color.toElmUi)
        , UiFont.color (fontColor |> Color.toElmUi)
        , Ui.width Ui.fill
        , Ui.paddingXY Style.spacing.size3 Style.spacing.size2
        ]
        { onPress = Just (config.onStateUpdated newStateOnPress)
        , label =
            Ui.row
                [ Ui.spacing Style.spacing.size1
                ]
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
