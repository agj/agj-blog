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

import Color exposing (Color)
import Custom.Color as Color
import Custom.Element as Ui
import Element as Ui
import Element.Background as UiBackground
import Element.Border as UiBorder
import Element.Font as UiFont
import Element.Input as UiInput
import Icon
import Markdown.Html
import Style
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


view : State -> AudioPlayerWithConfig msg -> Ui.Element msg
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
            Ui.column
                [ UiBackground.color (Style.color.layout05 |> Color.toElmUi)
                ]
                [ titleView state config firstTrack audioPlayer.title
                , Ui.column []
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
            Ui.none



-- INTERNAL


titleView : StateInternal -> Config msg -> Track -> String -> Ui.Element msg
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
    UiInput.button
        [ UiBorder.rounded 0
        , UiBackground.color (Style.color.layout40 |> Color.toElmUi)
        , UiFont.color (Style.color.white |> Color.toElmUi)
        , Ui.width Ui.fill
        , Ui.varPaddingTop Style.spacing.size2
        , Ui.varPaddingBottom Style.spacing.size2
        , Ui.varPaddingLeft Style.spacing.size3
        , Ui.varPaddingRight Style.spacing.size3
        ]
        { onPress = Just (config.onStateUpdated (State { state | playState = newPlayStateOnPress }))
        , label =
            Ui.row
                [ Ui.varSpacing Style.spacing.size1
                ]
                [ icon Icon.Medium
                , Ui.text title
                ]
        }
