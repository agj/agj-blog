module CustomMarkup exposing (toElmUi)

import CustomMarkup.AudioPlayer
import CustomMarkup.AudioPlayer.Track exposing (Track)
import CustomMarkup.LanguageBreak
import CustomMarkup.VideoEmbed
import Element as Ui
import Element.Font as UiFont
import List.Extra as List
import Markdown.Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Result.Extra as Result
import View.Figure
import View.TextBlock


toElmUi : String -> Ui.Element msg
toElmUi markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render elmUiRenderer)
        |> Result.map (List.map Tuple.first)
        |> Result.mapError renderErrorMessageAsElmUi
        |> Result.merge
        |> Ui.column []



-- INTERNAL


{-| Identifies characteristics of an Elm UI element for use while parsing markdown.
-}
type ElmUiTag
    = Block
    | Inline


elmUiRenderer : Markdown.Renderer.Renderer ( Ui.Element msg, ElmUiTag )
elmUiRenderer =
    let
        getEls : List ( Ui.Element msg, ElmUiTag ) -> List (Ui.Element msg)
        getEls =
            List.map Tuple.first
    in
    { blockQuote = \elTagPairs -> ( Ui.row [] (getEls elTagPairs), Block )
    , codeBlock = \{ body, language } -> ( Ui.text body, Block )
    , codeSpan = \code -> ( Ui.text code, Inline )
    , emphasis =
        \elTagPairs ->
            ( Ui.paragraph [ UiFont.italic ] (getEls elTagPairs)
            , Inline
            )
    , hardLineBreak = ( Ui.text "\n", Block )
    , heading =
        \{ level, rawText, children } ->
            let
                constructor =
                    case level of
                        Markdown.Block.H1 ->
                            View.TextBlock.heading1

                        Markdown.Block.H2 ->
                            View.TextBlock.heading2

                        Markdown.Block.H3 ->
                            View.TextBlock.heading3

                        Markdown.Block.H4 ->
                            View.TextBlock.heading4

                        Markdown.Block.H5 ->
                            View.TextBlock.heading5

                        Markdown.Block.H6 ->
                            View.TextBlock.heading6
            in
            ( constructor (getEls children)
                |> View.TextBlock.view
            , Block
            )
    , html =
        Markdown.Html.oneOf
            [ CustomMarkup.VideoEmbed.renderer
                |> renderFailableToElmUi (CustomMarkup.VideoEmbed.toElmUi >> always)
            , CustomMarkup.LanguageBreak.renderer
                |> renderFailableToElmUi (CustomMarkup.LanguageBreak.toElmUi >> always)
            , CustomMarkup.AudioPlayer.renderer
                |> renderToElmUi CustomMarkup.AudioPlayer.toElmUi
            , CustomMarkup.AudioPlayer.Track.renderer
                |> renderToElmUi (CustomMarkup.AudioPlayer.Track.toElmUi >> always)
            ]
    , image =
        \{ alt, src, title } ->
            ( Ui.image [] { src = src, description = alt }
                |> View.Figure.figure
                |> View.Figure.view
            , Block
            )
    , link =
        \{ title, destination } elTagPairs ->
            ( Ui.link []
                { url = destination
                , label =
                    Ui.paragraph [] (getEls elTagPairs)
                }
            , Inline
            )
    , orderedList =
        \startNumber items ->
            ( items
                |> List.map (getEls >> Ui.paragraph [])
                |> Ui.column []
            , Block
            )
    , paragraph =
        \elTagPairs ->
            case elTagPairs of
                [ ( child, Block ) ] ->
                    ( child, Block )

                _ ->
                    ( View.TextBlock.paragraph (getEls elTagPairs)
                        |> View.TextBlock.view
                    , Block
                    )
    , strikethrough =
        \elTagPairs ->
            ( Ui.paragraph [ UiFont.strike ] (getEls elTagPairs)
            , Inline
            )
    , strong =
        \elTagPairs ->
            ( Ui.paragraph [ UiFont.bold ] (getEls elTagPairs)
            , Inline
            )
    , table =
        \elTagPairs ->
            ( Ui.column [] (getEls elTagPairs)
            , Block
            )
    , tableBody = \elTagPairs -> ( Ui.column [] (getEls elTagPairs), Block )
    , tableCell = \mAlignment elTagPairs -> ( Ui.paragraph [] (getEls elTagPairs), Block )
    , tableHeader = \elTagPairs -> ( Ui.column [] (getEls elTagPairs), Block )
    , tableHeaderCell = \mAlignment elTagPairs -> ( Ui.row [] (getEls elTagPairs), Block )
    , tableRow = \elTagPairs -> ( Ui.row [] (getEls elTagPairs), Block )
    , text = \text -> ( Ui.text text, Inline )
    , thematicBreak = ( Ui.text "---", Block )
    , unorderedList =
        \items ->
            ( Ui.column []
                (items
                    |> List.map
                        (\(Markdown.Block.ListItem task elTagPairs) ->
                            Ui.paragraph [] (getEls elTagPairs)
                        )
                )
            , Block
            )
    }


renderToElmUi :
    (a -> List (Ui.Element msg) -> Ui.Element msg)
    -> Markdown.Html.Renderer a
    -> Markdown.Html.Renderer (List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag ))
renderToElmUi toElmUi_ renderer =
    renderer
        |> Markdown.Html.map
            (\value elTagPairs ->
                ( toElmUi_ value (List.map Tuple.first elTagPairs)
                , Block
                )
            )


renderFailableToElmUi :
    (a -> List (Ui.Element msg) -> Ui.Element msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag ))
renderFailableToElmUi okToElmUi renderer =
    renderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    ( Ui.column [] (renderErrorMessageAsElmUi err)
                    , Block
                    )
                )
                (\okResult elTagPairs ->
                    ( okToElmUi okResult (List.map Tuple.first elTagPairs)
                    , Block
                    )
                )
            )
        |> Markdown.Html.map Result.merge


renderErrorMessageAsElmUi : String -> List (Ui.Element msg)
renderErrorMessageAsElmUi error =
    [ Ui.paragraph []
        [ Ui.text "Parsing error:" ]
    , Ui.text error
    ]
