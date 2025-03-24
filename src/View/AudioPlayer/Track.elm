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

import Custom.Html
import Html exposing (Html)
import Html.Attributes exposing (class, classList)
import Html.Events
import Icon
import Json.Decode as Decode exposing (Decoder)
import Markdown.Html
import TypedSvg as Svg
import TypedSvg.Attributes as Svg
import TypedSvg.Core
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


view : TrackWithConfig msg -> Html msg
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
            [ Html.Events.onMouseLeave (config.onHoverChanged False)
            , Html.Events.onMouseEnter (config.onHoverChanged True)
            ]

        { icon, fontColor, backgroundColor, newPlayStateOnPress, events } =
            case config.playState of
                StatePlaying ph ->
                    { fontColor = "text-white"
                    , backgroundColor = "bg-primary-50"
                    , icon = Icon.pause
                    , newPlayStateOnPress = StatePaused ph
                    , events = []
                    }

                StatePaused ph ->
                    { fontColor = "text-white"
                    , backgroundColor = "bg-primary-50"
                    , icon = Icon.play
                    , newPlayStateOnPress = StatePlaying ph
                    , events = []
                    }

                StateStopped ->
                    { fontColor = "text-layout-90"
                    , backgroundColor =
                        if config.hovered then
                            "bg-layout-20"

                        else
                            "bg-transparent"
                    , icon =
                        if config.hovered then
                            Icon.play

                        else
                            Icon.none
                    , newPlayStateOnPress = StatePlaying initialPlayhead
                    , events = hoverEvents
                    }

        buttonStyles =
            [ class ("w-full px-3 pt-2 " ++ fontColor)
            , classList [ ( "pb-2", not isSelected ) ]
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
                Custom.Html.none

        buttonEl =
            Html.button
                (buttonStyles
                    ++ events
                    ++ [ Html.Events.onClick (config.onPlayStateChanged newPlayStateOnPress) ]
                )
                [ Html.div [ class "flex flex-row gap-1" ]
                    [ icon Icon.Medium
                    , Html.text track.title
                    , audioPlayerEl
                    ]
                ]

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
                    |> Html.map (seekPosToNewState >> config.onPlayStateChanged)
                ]

            else
                [ buttonEl ]
    in
    Html.div [ class ("flex w-full flex-col " ++ backgroundColor) ]
        columnEls


stoppedPlayState : PlayState
stoppedPlayState =
    StateStopped


playingPlayState : PlayState
playingPlayState =
    StatePlaying initialPlayhead



-- INTERNAL


seekBarView : Playhead -> Html Float
seekBarView { currentTime, duration } =
    let
        barWidth =
            "0.5rem"

        halfBarWidth =
            "0.25rem"

        progress =
            Svg.rect
                [ Svg.x (Svg.px 0)
                , TypedSvg.Core.attribute "y" halfBarWidth
                , Svg.width (Svg.percent (currentTime / duration * 100))
                , TypedSvg.Core.attribute "height" halfBarWidth
                , Svg.fill (Svg.CSSVariable "--color-layout-90")
                ]
                []
    in
    Html.div
        [ class "w-full"
        , Html.Events.on "mousedown" trackMouseEventSeekPositionDecoder
        ]
        [ Svg.svg
            [ Svg.width (Svg.percent 100)
            , Html.Attributes.attribute "height" barWidth
            ]
            [ progress ]
        ]


audioPlayerElement :
    { src : String
    , isPlaying : Bool
    , currentTime : Float
    , onPlayStateChanged : PlayState -> msg
    , playState : PlayState
    }
    -> Html msg
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
