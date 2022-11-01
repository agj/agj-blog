module CustomMarkup.LanguageBreak exposing (renderer, stringToLanguage, toHtml)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Html


type alias LanguageBreak =
    { language : Maybe Language
    }


type Language
    = English
    | Spanish
    | Japanese
    | Mandarin


renderer : Markdown.Html.Renderer (Result String LanguageBreak)
renderer =
    Markdown.Html.tag "language-break" constructLanguageBreak
        |> Markdown.Html.withOptionalAttribute "language"


toHtml : LanguageBreak -> dropped -> Html msg
toHtml languageBreak _ =
    Html.hr [ Attr.id "language" ]
        []


stringToLanguage : String -> Result String Language
stringToLanguage str =
    case str of
        "eng" ->
            Ok English

        "spa" ->
            Ok Spanish

        "jap" ->
            Ok Japanese

        "cnm" ->
            Ok Mandarin

        _ ->
            Err ("Unknown language: " ++ str ++ ".")



-- INTERNAL


constructLanguageBreak : Maybe String -> Result String LanguageBreak
constructLanguageBreak languageM =
    case languageM of
        Nothing ->
            Ok (LanguageBreak Nothing)

        Just str ->
            stringToLanguage str
                |> Result.map (Just >> LanguageBreak)
