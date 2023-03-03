module CustomMarkup.ElmUiTag exposing (..)

import CustomMarkup.AudioPlayer.Track exposing (Track)
import Element as Ui


{-| Identifies characteristics of an Elm UI element for use while parsing markdown.
-}
type ElmUiTag msg
    = Block (Ui.Element msg)
    | Inline (Ui.Element msg)
    | Custom Metadata


type Metadata
    = AudioPlayerTrack Track
