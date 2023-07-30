module View.AudioPlayer.Track exposing
    ( Config
    , PlayState
    , Track
    , playingPlayState
    , renderer
    , stoppedPlayState
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
    { playState : PlayState
    , hovered : Bool
    , onHoverChanged : Bool -> msg
    , onPlayStateChanged : PlayState -> msg
    }


type PlayState
    = StateStopped
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


view : TrackWithConfig msg -> Ui.Element msg
view (TrackWithConfig track config) =
    let
        ( isSelected, isPlaying, playhead ) =
            case config.playState of
                StatePlaying ph ->
                    ( True, True, ph )

                StatePaused ph ->
                    ( True, False, ph )

                StateStopped ->
                    ( False, False, initialPlayhead )

        hoverEvents =
            [ UiEvents.onMouseLeave (config.onHoverChanged False)
            , UiEvents.onMouseEnter (config.onHoverChanged True)
            ]

        { icon, fontColor, backgroundColor, newPlayStateOnPress, events } =
            case config.playState of
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

                StateStopped ->
                    { fontColor = Style.color.layout50
                    , backgroundColor =
                        if config.hovered then
                            Style.color.secondary05

                        else
                            Style.color.transparent
                    , icon =
                        if config.hovered then
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
                    , onPlayStateChanged = config.onPlayStateChanged
                    , playState = config.playState
                    }

            else
                Ui.none

        buttonEl =
            UiInput.button (buttonStyles ++ events)
                { onPress = Just (config.onPlayStateChanged newPlayStateOnPress)
                , label =
                    Ui.row
                        [ Ui.spacing Style.spacing.size1
                        ]
                        [ icon Icon.Medium
                        , Ui.text track.title
                        , audioPlayerEl
                        ]
                }

        seekPosToNewState : Float -> PlayState
        seekPosToNewState seekPos =
            case config.playState of
                StatePlaying ph ->
                    StatePlaying { ph | currentTime = ph.duration * seekPos }

                StatePaused ph ->
                    StatePaused { ph | currentTime = ph.duration * seekPos }

                StateStopped ->
                    StateStopped

        columnEls =
            if isSelected then
                [ buttonEl
                , seekBarView playhead
                    |> Ui.map (seekPosToNewState >> config.onPlayStateChanged)
                ]

            else
                [ buttonEl ]
    in
    Ui.column
        [ Ui.width Ui.fill
        , UiBackground.color (backgroundColor |> Color.toElmUi)
        ]
        columnEls


stoppedPlayState : PlayState
stoppedPlayState =
    StateStopped


playingPlayState : PlayState
playingPlayState =
    StatePlaying initialPlayhead



-- INTERNAL


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
    , onPlayStateChanged : PlayState -> msg
    , playState : PlayState
    }
    -> Ui.Element msg
audioPlayerElement { src, isPlaying, currentTime, onPlayStateChanged, playState } =
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
            (playingTrackStateMsgDecoder { playState = playState, onPlayStateChanged = onPlayStateChanged })
        ]
        []
        |> Ui.html


initialPlayhead : Playhead
initialPlayhead =
    { currentTime = 0
    , duration = 0
    }


playingTrackStateMsgDecoder : { playState : PlayState, onPlayStateChanged : PlayState -> msg } -> Decoder msg
playingTrackStateMsgDecoder { playState, onPlayStateChanged } =
    playheadDecoder
        |> Decode.map
            (\newPlayhead ->
                case playState of
                    StatePlaying _ ->
                        StatePlaying newPlayhead

                    StatePaused _ ->
                        StatePaused newPlayhead

                    StateStopped ->
                        StateStopped
            )
        |> Decode.map onPlayStateChanged


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
