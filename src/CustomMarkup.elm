module CustomMarkup exposing (toElmUi)

import CustomMarkup.AudioPlayer
import CustomMarkup.AudioPlayer.Track exposing (Track)
import CustomMarkup.ElmUiTag as ElmUiTag exposing (ElmUiTag)
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
        |> Result.andThen (Markdown.Renderer.render renderer)
        |> Result.map (List.map Tuple.first)
        |> Result.mapError renderErrorMessage
        |> Result.merge
        |> Ui.column []



-- INTERNAL


renderer : Markdown.Renderer.Renderer ( Ui.Element msg, ElmUiTag )
renderer =
    { blockQuote = \elTagPairs -> ( Ui.row [] (getEls elTagPairs), ElmUiTag.Block )
    , codeBlock = \{ body, language } -> ( Ui.text body, ElmUiTag.Block )
    , codeSpan = \code -> ( Ui.text code, ElmUiTag.Inline )
    , emphasis = renderInlineWithStyle UiFont.italic
    , hardLineBreak = ( Ui.text "\n", ElmUiTag.Block )
    , heading = renderHeading
    , html =
        Markdown.Html.oneOf
            [ CustomMarkup.VideoEmbed.renderer
                |> renderFailableCustom (CustomMarkup.VideoEmbed.toElmUi >> always)
            , CustomMarkup.LanguageBreak.renderer
                |> renderFailableCustom (CustomMarkup.LanguageBreak.toElmUi >> always)
            , CustomMarkup.AudioPlayer.Track.renderer
                |> renderCustomTag Ui.none (\track _ -> ElmUiTag.Custom (ElmUiTag.AudioPlayerTrack track))
            , CustomMarkup.AudioPlayer.renderer
                |> renderCustomElement ElmUiTag.Block CustomMarkup.AudioPlayer.toElmUi
                |> Markdown.Html.map
                    (\toElmUi_ children ->
                        children
                            |> List.map Tuple.second
                            |> List.filterMap
                                (\tag ->
                                    case tag of
                                        ElmUiTag.Custom (ElmUiTag.AudioPlayerTrack track) ->
                                            Just track

                                        _ ->
                                            Nothing
                                )
                            |> toElmUi_
                    )
            ]
    , image =
        \{ alt, src, title } ->
            ( Ui.image [] { src = src, description = alt }
                |> View.Figure.figure
                |> View.Figure.view
            , ElmUiTag.Block
            )
    , link =
        \{ title, destination } elTagPairs ->
            ( Ui.link []
                { url = destination
                , label =
                    Ui.paragraph [] (getEls elTagPairs)
                }
            , ElmUiTag.Inline
            )
    , orderedList =
        \startNumber items ->
            ( items
                |> List.map (getEls >> Ui.paragraph [])
                |> Ui.column []
            , ElmUiTag.Block
            )
    , paragraph = renderParagraph
    , strikethrough = renderInlineWithStyle UiFont.strike
    , strong = renderInlineWithStyle UiFont.bold
    , table =
        \elTagPairs ->
            ( Ui.column [] (getEls elTagPairs)
            , ElmUiTag.Block
            )
    , tableBody = \elTagPairs -> ( Ui.column [] (getEls elTagPairs), ElmUiTag.Block )
    , tableCell = \mAlignment elTagPairs -> ( Ui.paragraph [] (getEls elTagPairs), ElmUiTag.Block )
    , tableHeader = \elTagPairs -> ( Ui.column [] (getEls elTagPairs), ElmUiTag.Block )
    , tableHeaderCell = \mAlignment elTagPairs -> ( Ui.row [] (getEls elTagPairs), ElmUiTag.Block )
    , tableRow = \elTagPairs -> ( Ui.row [] (getEls elTagPairs), ElmUiTag.Block )
    , text = \text -> ( Ui.text text, ElmUiTag.Inline )
    , thematicBreak = ( Ui.text "---", ElmUiTag.Block )
    , unorderedList =
        \items ->
            ( Ui.column []
                (items
                    |> List.map
                        (\(Markdown.Block.ListItem task elTagPairs) ->
                            Ui.paragraph [] (getEls elTagPairs)
                        )
                )
            , ElmUiTag.Block
            )
    }


renderInlineWithStyle : Ui.Attribute msg -> List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag )
renderInlineWithStyle attr elTagPairs =
    ( Ui.paragraph [ attr ] (getEls elTagPairs)
    , ElmUiTag.Inline
    )


renderParagraph : List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag )
renderParagraph elTagPairs =
    case elTagPairs of
        [ ( child, ElmUiTag.Block ) ] ->
            ( child, ElmUiTag.Block )

        _ ->
            ( View.TextBlock.paragraph (getEls elTagPairs)
                |> View.TextBlock.view
            , ElmUiTag.Block
            )


renderHeading :
    { level : Markdown.Block.HeadingLevel
    , rawText : String
    , children : List ( Ui.Element msg, ElmUiTag )
    }
    -> ( Ui.Element msg, ElmUiTag )
renderHeading { level, rawText, children } =
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
    , ElmUiTag.Block
    )


renderCustomElement :
    ElmUiTag
    -> (a -> b -> Ui.Element msg)
    -> Markdown.Html.Renderer a
    -> Markdown.Html.Renderer (b -> ( Ui.Element msg, ElmUiTag ))
renderCustomElement elmUiTag toElmUi_ customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value children ->
                ( toElmUi_ value children
                , elmUiTag
                )
            )


renderCustomTag :
    Ui.Element msg
    -> (a -> b -> ElmUiTag)
    -> Markdown.Html.Renderer a
    -> Markdown.Html.Renderer (b -> ( Ui.Element msg, ElmUiTag ))
renderCustomTag element toElmUiTag customRenderer =
    customRenderer
        |> Markdown.Html.map
            (\value children ->
                ( element
                , toElmUiTag value children
                )
            )


renderFailableCustom :
    (a -> List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag ))
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List ( Ui.Element msg, ElmUiTag ) -> ( Ui.Element msg, ElmUiTag ))
renderFailableCustom okToElmUi customRenderer =
    customRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ ->
                    ( Ui.column [] (renderErrorMessage err)
                    , ElmUiTag.Block
                    )
                )
                (\okResult elTagPairs ->
                    okToElmUi okResult elTagPairs
                )
            )
        |> Markdown.Html.map Result.merge


renderErrorMessage : String -> List (Ui.Element msg)
renderErrorMessage error =
    [ Ui.paragraph []
        [ Ui.text "Parsing error:" ]
    , Ui.text error
    ]


getEls : List ( Ui.Element msg, ElmUiTag ) -> List (Ui.Element msg)
getEls =
    List.map Tuple.first
