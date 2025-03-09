module View.LanguageBreak exposing
    ( LanguageBreak
    , renderer
    , view
    )

import Data.Language as Language exposing (Language)
import Html exposing (Html)
import Html.Attributes exposing (class)
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
        [ class "my-6 h-0.5 w-full border-0"
        , Html.Attributes.id "language"
        , Sand.backgroundColor Style.color.primary50
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
