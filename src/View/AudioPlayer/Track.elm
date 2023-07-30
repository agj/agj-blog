module View.AudioPlayer.Track exposing
    ( State
    , Track
    , renderer
    , view
    , withConfig
    )

import Custom.Color as Color
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Element.Events as UiEvents
import Element.Font as UiFont
import Element.Input as UiInput
import Html
import Html.Attributes
import Html.Events
import Icon
import Json.Decode as Decode exposing (Decoder)
import Markdown.Html
import Style
import TypedSvg as Svg
import TypedSvg.Attributes as Svg
import TypedSvg.Types as Svg


type alias Track =
    { title : String
    , src : String
    }


type TrackWithConfig msg
    = TrackWithConfig Track (Config msg)


type alias Config msg =
    { onStateUpdated : State -> msg
    }


type State
    = State State_


type alias State_ =
    { playState : PlayState
    , hovered : Bool
    }


type PlayState
    = StateNotPlaying
    | StatePlaying Playhead
    | StatePaused Playhead


type alias Playhead =
    { currentTime : Float
    , duration : Float
    }


renderer : Markdown.Html.Renderer Track
renderer =
    Markdown.Html.tag "track" Track
        |> Markdown.Html.withAttribute "title"
        |> Markdown.Html.withAttribute "src"


withConfig : Config msg -> Track -> TrackWithConfig msg
withConfig config track =
    TrackWithConfig track config


view : State -> TrackWithConfig msg -> Ui.Element msg
view (State state) (TrackWithConfig track config) =
    let
        ( isSelected, isPlaying, playhead ) =
            case state.playState of
                StatePlaying ph ->
                    ( True, True, ph )

                StatePaused ph ->
                    ( True, False, ph )

                StateNotPlaying ->
                    ( False, False, initialPlayhead )

        hoverEvents =
            [ UiEvents.onMouseLeave (config.onStateUpdated (State { state | hovered = False }))
            , UiEvents.onMouseEnter (config.onStateUpdated (State { state | hovered = True }))
            ]

        { icon, fontColor, backgroundColor, newPlayStateOnPress, events } =
            case state.playState of
                StatePlaying ph ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.pause
                    , newPlayStateOnPress = StatePaused ph
                    , events = []
                    }

                StatePaused ph ->
                    { fontColor = Style.color.white
                    , backgroundColor = Style.color.secondary50
                    , icon = Icon.play
                    , newPlayStateOnPress = StatePlaying ph
                    , events = []
                    }

                StateNotPlaying ->
                    { fontColor = Style.color.layout50
                    , backgroundColor =
                        if state.hovered then
                            Style.color.secondary05

                        else
                            Style.color.transparent
                    , icon =
                        if state.hovered then
                            Icon.play

                        else
                            Icon.none
                    , newPlayStateOnPress = StatePlaying initialPlayhead
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
                    , isPlaying = isPlaying
                    , currentTime = playhead.currentTime
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
            let
                newPlayState =
                    case state.playState of
                        StatePlaying ph ->
                            StatePlaying { ph | currentTime = ph.duration * seekPos }

                        StatePaused ph ->
                            StatePaused { ph | currentTime = ph.duration * seekPos }

                        StateNotPlaying ->
                            StateNotPlaying
            in
            State { state | playState = newPlayState }

        columnEls =
            if isSelected then
                [ buttonEl
                , seekBarView playhead
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


seekBarView : Playhead -> Ui.Element Float
seekBarView { currentTime, duration } =
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


audioPlayerElement :
    { src : String
    , isPlaying : Bool
    , currentTime : Float
    , onStateUpdated : State -> msg
    , state : State_
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


initialPlayhead : Playhead
initialPlayhead =
    { currentTime = 0
    , duration = 0
    }


playingTrackStateMsgDecoder : { state : State_, onStateUpdated : State -> msg } -> Decoder msg
playingTrackStateMsgDecoder { state, onStateUpdated } =
    playheadDecoder
        |> Decode.map
            (\newPlayhead ->
                case state.playState of
                    StatePlaying _ ->
                        StatePlaying newPlayhead

                    StatePaused _ ->
                        StatePaused newPlayhead

                    StateNotPlaying ->
                        StateNotPlaying
            )
        |> Decode.map
            (\newPlayState ->
                onStateUpdated (State { state | playState = newPlayState })
            )


playheadDecoder : Decoder Playhead
playheadDecoder =
    Decode.map2 Playhead
        (Decode.at [ "detail", "currentTime" ] Decode.float)
        (Decode.at [ "detail", "duration" ] Decode.float)


trackMouseEventSeekPositionDecoder : Decoder Float
trackMouseEventSeekPositionDecoder =
    Decode.map2 (\offsetX targetWidth -> offsetX / targetWidth)
        (Decode.at [ "offsetX" ] Decode.float)
        (Decode.at [ "currentTarget", "offsetWidth" ] Decode.float)
