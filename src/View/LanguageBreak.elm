module View.LanguageBreak exposing
    ( LanguageBreak
    , renderer
    , view
    )

import Data.Language as Language exposing (Language)
import Html exposing (Html)
import Html.Attributes
import Markdown.Html
import Sand
import Style


type alias LanguageBreak =
    { language : Maybe Language
    }


renderer : Markdown.Html.Renderer (Result String LanguageBreak)
renderer =
    Markdown.Html.tag "language-break" constructLanguageBreak
        |> Markdown.Html.withOptionalAttribute "language"


view : LanguageBreak -> Html msg
view languageBreak =
    Html.hr
        [ Html.Attributes.id "language"
        , Sand.marginTop Sand.L6
        , Sand.marginBottom Sand.L6
        , Sand.height Sand.L1
        , Sand.width (Sand.LRaw "100%")
        , Sand.backgroundColor Style.color.primary50
        , Html.Attributes.style "border" "none"
        ]
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
