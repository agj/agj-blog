module CustomMarkup.ElmUiTag exposing (..)

import Element as Ui
import View.AudioPlayer.Track exposing (Track)


{-| Identifies characteristics of an Elm UI element for use while parsing markdown.
-}
type ElmUiTag msg
    = Block (Ui.Element msg)
    | Inline (Ui.Element msg)
    | Custom Metadata


type Metadata
    = AudioPlayerTrack Track
