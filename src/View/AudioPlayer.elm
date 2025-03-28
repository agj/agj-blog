module View.AudioPlayer exposing
    ( AudioPlayer
    , AudioPlayerWithConfig
    , Config
    , State
    , initialState
    , renderer
    , view
    , withConfig
    )

import Custom.Html
import Html exposing (Html)
import Html.Attributes exposing (class)
import Html.Events
import Icon
import Markdown.Html
import View.AudioPlayer.Track as Track exposing (Track)


type alias AudioPlayer =
    { title : String
    }


type AudioPlayerWithConfig msg
    = AudioPlayerWithConfig AudioPlayer (Config msg)


type alias Config msg =
    { onStateUpdated : State -> msg
    , tracks : List Track
    }


type State
    = State StateInternal


type alias StateInternal =
    { playState : PlayState
    , hovered : Maybe Track
    }


type PlayState
    = NoTrackSelected
    | TrackSelected Track Track.PlayState


initialState : State
initialState =
    State
        { playState = NoTrackSelected
        , hovered = Nothing
        }


renderer : Markdown.Html.Renderer AudioPlayer
renderer =
    Markdown.Html.tag "audio-player" AudioPlayer
        |> Markdown.Html.withAttribute "title"


withConfig : Config msg -> AudioPlayer -> AudioPlayerWithConfig msg
withConfig config audioPlayer =
    AudioPlayerWithConfig audioPlayer config


view : State -> AudioPlayerWithConfig msg -> Html msg
view (State state) (AudioPlayerWithConfig audioPlayer config) =
    let
        onHoverChanged : Track -> Bool -> msg
        onHoverChanged track hovered =
            let
                newHovered =
                    if hovered then
                        Just track

                    else if state.hovered == Just track then
                        Nothing

                    else
                        state.hovered
            in
            config.onStateUpdated (State { state | hovered = newHovered })

        trackPlayState : Track -> Track.PlayState
        trackPlayState track =
            case state.playState of
                TrackSelected currentTrack currentTrackPlayState ->
                    if currentTrack == track then
                        currentTrackPlayState

                    else
                        Track.stoppedPlayState

                NoTrackSelected ->
                    Track.stoppedPlayState

        trackConfig : Track -> Track.Config msg
        trackConfig track =
            { playState = trackPlayState track
            , hovered = state.hovered == Just track
            , onHoverChanged = onHoverChanged track
            , onPlayStateChanged =
                \newPlayState ->
                    config.onStateUpdated
                        (State { state | playState = TrackSelected track newPlayState })
            }
    in
    case config.tracks of
        firstTrack :: _ ->
            Html.div [ class "bg-layout-20 flex flex-col" ]
                [ titleView state config firstTrack audioPlayer.title
                , Html.div [ class "flex flex-col" ]
                    (config.tracks
                        |> List.map
                            (\track ->
                                track
                                    |> Track.withConfig (trackConfig track)
                                    |> Track.view
                            )
                    )
                ]

        [] ->
            Custom.Html.none



-- INTERNAL


titleView : StateInternal -> Config msg -> Track -> String -> Html msg
titleView state config firstTrack title =
    let
        ( newPlayStateOnPress, icon ) =
            case state.playState of
                TrackSelected _ _ ->
                    ( NoTrackSelected
                    , Icon.stop
                    )

                NoTrackSelected ->
                    ( TrackSelected firstTrack Track.playingPlayState
                    , Icon.play
                    )
    in
    Html.button
        [ class "bg-layout-60 text-layout-10 w-full px-3 py-2"
        , Html.Events.onClick (config.onStateUpdated (State { state | playState = newPlayStateOnPress }))
        ]
        [ Html.div [ class "flex flex-row gap-1" ]
            [ icon Icon.Medium
            , Html.text title
            ]
        ]
