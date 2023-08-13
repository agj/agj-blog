module View.LanguageBreak exposing
    ( LanguageBreak
    , renderer
    , view
    )

import Custom.Color as Color
import Custom.Element as Ui
import CustomMarkup.ElmUiTag exposing (ElmUiTag)
import Data.Language as Language exposing (Language)
import Element as Ui
import Element.Background as UiBackground
import Markdown.Html
import Style


type alias LanguageBreak =
    { language : Maybe Language
    }


renderer : Markdown.Html.Renderer (Result String LanguageBreak)
renderer =
    Markdown.Html.tag "language-break" constructLanguageBreak
        |> Markdown.Html.withOptionalAttribute "language"


view : LanguageBreak -> Ui.Element msg
view languageBreak =
    let
        rule =
            Ui.el
                [ Ui.width Ui.fill
                , Ui.height (Ui.px 1)
                , UiBackground.color (Style.color.secondary50 |> Color.toElmUi)
                , Ui.id "language"
                ]
                Ui.none
    in
    Ui.el
        [ Ui.width Ui.fill
        , Ui.paddingXY 0 Style.spacing.size5
        ]
        rule



-- INTERNAL


constructLanguageBreak : Maybe String -> Result String LanguageBreak
constructLanguageBreak languageM =
    case languageM of
        Nothing ->
            Ok (LanguageBreak Nothing)

        Just str ->
            Language.fromString str
                |> Result.map (Just >> LanguageBreak)
