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
    = State StateInternal


type alias StateInternal =
    { playState : PlayState
    , hovered : Maybe Track
    }


type PlayState
    = Stopped
    | Playing Track
    | Paused Track


type TrackStatus
    = PlayingTrack
    | PausedTrack
    | InactiveTrack


initialState : State
initialState =
    State
        { playState = Stopped
        , hovered = Nothing
        }


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


toElmUi : State -> Config msg -> AudioPlayer -> List Track -> Ui.Element msg
toElmUi (State state) config audioPlayer tracks =
    case tracks of
        firstTrack :: _ ->
            Ui.column
                [ UiBackground.color (Style.color.layout05 |> Color.toElmUi)
                ]
                [ titleToElmUi state config firstTrack audioPlayer.title
                , Ui.column []
                    (tracks
                        |> List.map
                            (\track -> trackToElmUi state config track)
                    )
                ]

        [] ->
            Ui.none



-- INTERNAL


titleToElmUi : StateInternal -> Config msg -> Track -> String -> Ui.Element msg
titleToElmUi state config firstTrack title =
    let
        ( newPlayStateOnPress, icon ) =
            case state.playState of
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
        { onPress = Just (config.onStateUpdated (State { state | playState = newPlayStateOnPress }))
        , label =
            Ui.row
                [ Ui.spacing Style.spacing.size1
                ]
                [ icon Icon.Medium
                , Ui.text title
                ]
        }


trackToElmUi : StateInternal -> Config msg -> Track -> Ui.Element msg
trackToElmUi state config track =
    let
        status =
            getTrackStatus state track

        { icon, fontColor, backgroundColor, newPlayStateOnPress } =
            case status of
                PlayingTrack ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.pause
                    , newPlayStateOnPress = Paused track
                    }

                PausedTrack ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.play
                    , newPlayStateOnPress = Playing track
                    }

                InactiveTrack ->
                    { fontColor = Style.color.layout50
                    , backgroundColor = Style.color.transparent
                    , icon = Icon.none
                    , newPlayStateOnPress = Playing track
                    }
    in
    UiInput.button
        [ UiBorder.rounded 0
        , UiBackground.color (backgroundColor |> Color.toElmUi)
        , UiFont.color (fontColor |> Color.toElmUi)
        , Ui.width Ui.fill
        , Ui.paddingXY Style.spacing.size3 Style.spacing.size2
        ]
        { onPress = Just (config.onStateUpdated (State { state | playState = newPlayStateOnPress }))
        , label =
            Ui.row
                [ Ui.spacing Style.spacing.size1
                ]
                [ icon Icon.Medium
                , Ui.text track.title
                ]
        }


getTrackStatus : StateInternal -> Track -> TrackStatus
getTrackStatus state track =
    case state.playState of
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
