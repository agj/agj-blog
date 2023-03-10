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
import Element.Events as UiEvents
import Element.Font as UiFont
import Element.Input as UiInput
import Element.Keyed as UiKeyed
import Html
import Html.Attributes
import Html.Events
import Icon
import Json.Decode as Decode exposing (Decoder)
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
    | Playing Track PlayingTrackState
    | Paused Track PlayingTrackState


type alias PlayingTrackState =
    { currentTime : Float
    , duration : Float
    }


initialPlayingTrackState : PlayingTrackState
initialPlayingTrackState =
    { currentTime = 0, duration = 0 }


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
                Playing _ _ ->
                    ( Stopped
                    , Icon.stop
                    )

                Paused _ _ ->
                    ( Stopped
                    , Icon.stop
                    )

                Stopped ->
                    ( Playing firstTrack initialPlayingTrackState
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

        hoverEvents =
            [ UiEvents.onMouseLeave (config.onStateUpdated (State { state | hovered = Nothing }))
            , UiEvents.onMouseEnter (config.onStateUpdated (State { state | hovered = Just track }))
            ]

        playingTrackState =
            getPlayingTrackState state.playState
                |> Maybe.withDefault initialPlayingTrackState

        { icon, fontColor, backgroundColor, newPlayStateOnPress, events } =
            case status of
                PlayingTrack ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.pause
                    , newPlayStateOnPress = Paused track playingTrackState
                    , events = []
                    }

                PausedTrack ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.play
                    , newPlayStateOnPress = Playing track playingTrackState
                    , events = []
                    }

                InactiveTrack ->
                    { fontColor = Style.color.layout50
                    , backgroundColor =
                        if state.hovered == Just track then
                            Style.color.secondary05

                        else
                            Style.color.transparent
                    , icon =
                        if state.hovered == Just track then
                            Icon.play

                        else
                            Icon.none
                    , newPlayStateOnPress = Playing track initialPlayingTrackState
                    , events = hoverEvents
                    }

        buttonStyles =
            [ UiBorder.rounded 0
            , UiBackground.color (backgroundColor |> Color.toElmUi)
            , UiFont.color (fontColor |> Color.toElmUi)
            , Ui.width Ui.fill
            , Ui.paddingXY Style.spacing.size3 Style.spacing.size2
            ]

        audioPlayerEl =
            if status == PlayingTrack || status == PausedTrack then
                audioPlayerElement
                    { src = track.src
                    , isPlaying = status == PlayingTrack
                    , currentTime = playingTrackState.currentTime
                    , onStateUpdated = config.onStateUpdated
                    , state = state
                    }

            else
                Ui.none
    in
    UiInput.button (buttonStyles ++ events)
        { onPress = Just (config.onStateUpdated (State { state | playState = newPlayStateOnPress }))
        , label =
            Ui.row
                [ Ui.spacing Style.spacing.size1
                ]
                [ icon Icon.Medium
                , Ui.text track.title
                , audioPlayerEl
                ]
        }


getTrackStatus : StateInternal -> Track -> TrackStatus
getTrackStatus state track =
    case state.playState of
        Playing playingTrack _ ->
            if playingTrack == track then
                PlayingTrack

            else
                InactiveTrack

        Paused pausedTrack _ ->
            if pausedTrack == track then
                PausedTrack

            else
                InactiveTrack

        Stopped ->
            InactiveTrack


audioPlayerElement :
    { src : String
    , isPlaying : Bool
    , currentTime : Float
    , onStateUpdated : State -> msg
    , state : StateInternal
    }
    -> Ui.Element msg
audioPlayerElement { src, isPlaying, currentTime, onStateUpdated, state } =
    Html.node "audio-player"
        [ Html.Attributes.attribute "src" src
        , Html.Attributes.attribute "current-time" (String.fromFloat currentTime)
        , Html.Attributes.attribute "playing"
            (if isPlaying then
                "true"

             else
                "false"
            )
        , Html.Events.on "timeupdate"
            (playingTrackStateMsgDecoder { state = state, onStateUpdated = onStateUpdated })
        ]
        []
        |> Ui.html


getPlayingTrackState : PlayState -> Maybe PlayingTrackState
getPlayingTrackState playState =
    case playState of
        Playing _ playingTrackState ->
            Just playingTrackState

        Paused _ playingTrackState ->
            Just playingTrackState

        Stopped ->
            Nothing


playingTrackStateMsgDecoder : { state : StateInternal, onStateUpdated : State -> msg } -> Decoder msg
playingTrackStateMsgDecoder { state, onStateUpdated } =
    playingTrackStateDecoder
        |> Decode.map
            (\newPlayingTrackState ->
                case state.playState of
                    Playing track _ ->
                        Playing track newPlayingTrackState

                    Paused track _ ->
                        Paused track newPlayingTrackState

                    Stopped ->
                        state.playState
            )
        |> Decode.map
            (\newPlayState ->
                onStateUpdated (State { state | playState = newPlayState })
            )


playingTrackStateDecoder : Decoder PlayingTrackState
playingTrackStateDecoder =
    Decode.map2 PlayingTrackState
        (Decode.at [ "detail", "currentTime" ] Decode.float)
        (Decode.at [ "detail", "duration" ] Decode.float)
