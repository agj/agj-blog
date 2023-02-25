module CustomMarkup.AudioPlayer.Track exposing
    ( Track
    , renderer
    , toElmUi
    )

import CustomMarkup.ElmUiTag exposing (ElmUiTag)
import Element as Ui
import Markdown.Html


type alias Track =
    { title : String
    , src : String
    }


renderer : Markdown.Html.Renderer Track
renderer =
    Markdown.Html.tag "track" Track
        |> Markdown.Html.withAttribute "title"
        |> Markdown.Html.withAttribute "src"


toElmUi : Track -> ( Ui.Element msg, ElmUiTag )
toElmUi track =
    ( Ui.none, CustomMarkup.ElmUiTag.Custom (CustomMarkup.ElmUiTag.AudioPlayerTrack track) )
