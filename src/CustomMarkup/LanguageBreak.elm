module CustomMarkup.LanguageBreak exposing
    ( renderer
    , toElmUi
    , toHtml
    )

import Data.Language as Language exposing (Language)
import Element as Ui
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Html


type alias LanguageBreak =
    { language : Maybe Language
    }


renderer : Markdown.Html.Renderer (Result String LanguageBreak)
renderer =
    Markdown.Html.tag "language-break" constructLanguageBreak
        |> Markdown.Html.withOptionalAttribute "language"


toElmUi : LanguageBreak -> dropped -> Ui.Element msg
toElmUi languageBreak _ =
    toHtml languageBreak ()
        |> Ui.html


toHtml : LanguageBreak -> dropped -> Html msg
toHtml languageBreak _ =
    Html.hr [ Attr.id "language" ]
        []



-- INTERNAL


constructLanguageBreak : Maybe String -> Result String LanguageBreak
constructLanguageBreak languageM =
    case languageM of
        Nothing ->
            Ok (LanguageBreak Nothing)

        Just str ->
            Language.fromString str
                |> Result.map (Just >> LanguageBreak)
