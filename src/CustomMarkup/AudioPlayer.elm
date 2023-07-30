module CustomMarkup.AudioPlayer exposing
    ( AudioPlayer
    , Config
    , State
    , initialState
    , renderer
    , toElmUi
    )

import Color exposing (Color)
import Custom.Color as Color
import CustomMarkup.AudioPlayer.Track exposing (Track)
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Element.Events as UiEvents
import Element.Font as UiFont
import Element.Input as UiInput
import Element.Keyed as UiKeyed
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icon
import Json.Decode as Decode exposing (Decoder)
import Markdown.Html
import Style
import TypedSvg as Svg
import TypedSvg.Attributes as Svg
import TypedSvg.Types as Svg


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
    = StoppedState
    | PlayingState Track PlayingTrackState
    | PausedState Track PlayingTrackState


type alias PlayingTrackState =
    { currentTime : Float
    , duration : Float
    }


type TrackStatus
    = TrackPlaying
    | TrackPaused
    | TrackInactive


initialState : State
initialState =
    State
        { playState = StoppedState
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


initialPlayingTrackState : PlayingTrackState
initialPlayingTrackState =
    { currentTime = 0, duration = 0 }


titleToElmUi : StateInternal -> Config msg -> Track -> String -> Ui.Element msg
titleToElmUi state config firstTrack title =
    let
        ( newPlayStateOnPress, icon ) =
            case state.playState of
                PlayingState _ _ ->
                    ( StoppedState
                    , Icon.stop
                    )

                PausedState _ _ ->
                    ( StoppedState
                    , Icon.stop
                    )

                StoppedState ->
                    ( PlayingState firstTrack initialPlayingTrackState
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
        trackStatus =
            getTrackStatus state track

        playingTrackState =
            getPlayingTrackState state.playState
                |> Maybe.withDefault initialPlayingTrackState

        isSelected =
            trackStatus == TrackPlaying || trackStatus == TrackPaused

        hoverEvents =
            [ UiEvents.onMouseLeave (config.onStateUpdated (State { state | hovered = Nothing }))
            , UiEvents.onMouseEnter (config.onStateUpdated (State { state | hovered = Just track }))
            ]

        { icon, fontColor, backgroundColor, newPlayStateOnPress, events } =
            case trackStatus of
                TrackPlaying ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.pause
                    , newPlayStateOnPress = PausedState track playingTrackState
                    , events = []
                    }

                TrackPaused ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.play
                    , newPlayStateOnPress = PlayingState track playingTrackState
                    , events = []
                    }

                TrackInactive ->
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
                    , newPlayStateOnPress = PlayingState track initialPlayingTrackState
                    , events = hoverEvents
                    }

        buttonStyles =
            [ UiBorder.rounded 0
            , UiBackground.color (Style.color.transparent |> Color.toElmUi)
            , UiFont.color (fontColor |> Color.toElmUi)
            , Ui.width Ui.fill
            , Ui.paddingEach
                { left = Style.spacing.size3
                , right = Style.spacing.size3
                , top = Style.spacing.size2
                , bottom =
                    if isSelected then
                        0

                    else
                        Style.spacing.size2
                }
            ]

        audioPlayerEl =
            if isSelected then
                audioPlayerElement
                    { src = track.src
                    , isPlaying = trackStatus == TrackPlaying
                    , currentTime = playingTrackState.currentTime
                    , onStateUpdated = config.onStateUpdated
                    , state = state
                    }

            else
                Ui.none

        buttonEl =
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

        seekPosToNewState : Float -> State
        seekPosToNewState seekPos =
            case trackStatus of
                TrackPlaying ->
                    State
                        { state
                            | playState =
                                PlayingState track
                                    { playingTrackState | currentTime = playingTrackState.duration * seekPos }
                        }

                TrackPaused ->
                    State
                        { state
                            | playState =
                                PausedState track
                                    { playingTrackState | currentTime = playingTrackState.duration * seekPos }
                        }

                TrackInactive ->
                    State state

        columnEls =
            if isSelected then
                [ buttonEl
                , trackBar playingTrackState
                    |> Ui.map (seekPosToNewState >> config.onStateUpdated)
                ]

            else
                [ buttonEl ]
    in
    Ui.column
        [ Ui.width Ui.fill
        , UiBackground.color (backgroundColor |> Color.toElmUi)
        ]
        columnEls


trackBar : PlayingTrackState -> Ui.Element Float
trackBar { currentTime, duration } =
    let
        barWidth =
            2

        progress =
            Svg.rect
                [ Svg.x (Svg.px 0)
                , Svg.y (Svg.px (Style.spacing.size2 - barWidth))
                , Svg.width (Svg.percent (currentTime / duration * 100))
                , Svg.height (Svg.px barWidth)
                , Svg.fill (Svg.Paint Style.color.layout)
                ]
                []
    in
    Ui.el
        [ Ui.width Ui.fill
        , Html.Events.on "mousedown" trackMouseEventSeekPositionDecoder
            |> Ui.htmlAttribute
        ]
        (Svg.svg
            [ Svg.width (Svg.percent 100)
            , Svg.height (Svg.px Style.spacing.size2)
            ]
            [ progress ]
            |> Ui.html
        )


trackMouseEventSeekPositionDecoder : Decoder Float
trackMouseEventSeekPositionDecoder =
    Decode.map2 (\offsetX targetWidth -> offsetX / targetWidth)
        (Decode.at [ "offsetX" ] Decode.float)
        (Decode.at [ "currentTarget", "offsetWidth" ] Decode.float)


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


getTrackStatus : StateInternal -> Track -> TrackStatus
getTrackStatus state track =
    case state.playState of
        PlayingState playingTrack _ ->
            if playingTrack == track then
                TrackPlaying

            else
                TrackInactive

        PausedState pausedTrack _ ->
            if pausedTrack == track then
                TrackPaused

            else
                TrackInactive

        StoppedState ->
            TrackInactive


getPlayingTrackState : PlayState -> Maybe PlayingTrackState
getPlayingTrackState playState =
    case playState of
        PlayingState _ playingTrackState ->
            Just playingTrackState

        PausedState _ playingTrackState ->
            Just playingTrackState

        StoppedState ->
            Nothing


playingTrackStateMsgDecoder : { state : StateInternal, onStateUpdated : State -> msg } -> Decoder msg
playingTrackStateMsgDecoder { state, onStateUpdated } =
    playingTrackStateDecoder
        |> Decode.map
            (\newPlayingTrackState ->
                case state.playState of
                    PlayingState track _ ->
                        PlayingState track newPlayingTrackState

                    PausedState track _ ->
                        PausedState track newPlayingTrackState

                    StoppedState ->
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
