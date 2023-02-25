module CustomMarkup.ElmUiTag exposing (..)

import CustomMarkup.AudioPlayer.Track exposing (Track)


{-| Identifies characteristics of an Elm UI element for use while parsing markdown.
-}
type ElmUiTag
    = Block
    | Inline
    | Custom Metadata


type Metadata
    = AudioPlayerTrack Track
