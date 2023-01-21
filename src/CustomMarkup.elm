module CustomMarkup exposing
    ( toElmUi
    , toHtml
    )

import CustomMarkup.AudioPlayer
import CustomMarkup.AudioPlayer.Track exposing (Track)
import CustomMarkup.LanguageBreak
import CustomMarkup.VideoEmbed
import Element as Ui
import Element.Font as UiFont
import Html exposing (Html)
import Html.Attributes as Attr
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


toHtml : String -> List (Html msg)
toHtml markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render htmlRenderer)
        |> Result.mapError renderErrorMessageAsHtml
        |> Result.merge



-- INTERNAL
-- Elm UI Rendering


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
                |> resultToElmUi CustomMarkup.VideoEmbed.toElmUi
            , CustomMarkup.LanguageBreak.renderer
                |> resultToElmUi CustomMarkup.LanguageBreak.toElmUi
            , CustomMarkup.AudioPlayer.renderer
                |> Markdown.Html.map
                    (\ap elTagPairs ->
                        ( CustomMarkup.AudioPlayer.toElmUi ap (getEls elTagPairs)
                        , Block
                        )
                    )
            , CustomMarkup.AudioPlayer.Track.renderer
                |> Markdown.Html.map
                    (\track _ ->
                        ( CustomMarkup.AudioPlayer.Track.toElmUi track ()
                        , Block
                        )
                    )
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


resultToElmUi :
    (a -> List (Ui.Element msg) -> Ui.Element msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag ))
resultToElmUi partialToHtml resultRenderer =
    resultRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    ( Ui.column [] (renderErrorMessageAsElmUi err)
                    , Block
                    )
                )
                (\a children ->
                    ( partialToHtml a (List.map Tuple.first children)
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



-- HTML Rendering


htmlRenderer : Markdown.Renderer.Renderer (Html msg)
htmlRenderer =
    let
        defRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defRenderer
        | html =
            Markdown.Html.oneOf
                [ CustomMarkup.VideoEmbed.renderer
                    |> resultToHtml CustomMarkup.VideoEmbed.toHtml
                , CustomMarkup.LanguageBreak.renderer
                    |> resultToHtml CustomMarkup.LanguageBreak.toHtml
                , CustomMarkup.AudioPlayer.renderer
                    |> Markdown.Html.map CustomMarkup.AudioPlayer.toHtml
                , CustomMarkup.AudioPlayer.Track.renderer
                    |> Markdown.Html.map CustomMarkup.AudioPlayer.Track.toHtml
                ]
        , heading = renderHeading
        , image = renderImage
    }


renderErrorMessageAsHtml : String -> List (Html msg)
renderErrorMessageAsHtml error =
    [ Html.p []
        [ Html.text "Parsing error:"
        ]
    , Html.pre []
        [ Html.code [] [ Html.text error ]
        ]
    ]


resultToHtml :
    (a -> List (Html msg) -> Html msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List (Html msg) -> Html msg)
resultToHtml partialToHtml resultRenderer =
    resultRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ -> Html.div [] (renderErrorMessageAsHtml err))
                partialToHtml
            )
        |> Markdown.Html.map Result.merge


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List (Html msg)
    }
    -> Html msg
renderHeading { level, rawText, children } =
    case level of
        Markdown.Block.H1 ->
            Html.h2 [] children

        Markdown.Block.H2 ->
            Html.h3 [] children

        Markdown.Block.H3 ->
            Html.h4 [] children

        Markdown.Block.H4 ->
            Html.h5 [] children

        Markdown.Block.H5 ->
            Html.h6 [] children

        Markdown.Block.H6 ->
            Html.p []
                [ Html.strong [] children
                ]


renderImage : { alt : String, src : String, title : Maybe String } -> Html msg
renderImage { alt, src, title } =
    let
        figcaption =
            case title of
                Just t ->
                    [ Html.figcaption [] [ Html.text t ] ]

                Nothing ->
                    []
    in
    Html.figure []
        (Html.img
            [ Attr.src src
            , Attr.alt alt
            ]
            []
            :: figcaption
        )
