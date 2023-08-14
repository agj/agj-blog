module Doc.Render exposing (..)

import Custom.Color as Color
import Doc
import Element as Ui
import Element.Background as UiBackground
import Style
import View.CodeBlock
import View.Column exposing (Spacing(..))
import View.Figure
import View.Heading
import View.Inline
import View.LanguageBreak
import View.List
import View.Paragraph
import View.VideoEmbed


toElmUi : List Doc.Block -> Ui.Element msg
toElmUi blocks =
    blocks
        |> toElmUiInternal 1
        |> View.Column.setSpaced MSpacing



-- INTERNAL


toElmUiInternal : Int -> List Doc.Block -> List (Ui.Element msg)
toElmUiInternal sectionDepth blocks =
    case blocks of
        (Doc.Paragraph inlines) :: nextBlocks ->
            (inlines
                |> List.map inlineToElmUi
                |> View.Paragraph.view
            )
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.OrderedList firstItem restItems) :: nextBlocks ->
            listToElmUi sectionDepth (Just 1) firstItem restItems
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.UnorderedList firstItem restItems) :: nextBlocks ->
            listToElmUi sectionDepth Nothing firstItem restItems
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.BlockQuote blockQuoteBlocks) :: nextBlocks ->
            blockQuoteToElmUi sectionDepth blockQuoteBlocks
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.Section { heading, content }) :: nextBlocks ->
            let
                newSectionDepth =
                    sectionDepth + 1
            in
            ([ heading
                |> List.map inlineToElmUi
                |> View.Heading.view newSectionDepth
             , content
                |> toElmUiInternal newSectionDepth
                |> View.Column.setSpaced MSpacing
             ]
                |> View.Column.setSpaced MSpacing
            )
                :: toElmUiInternal newSectionDepth nextBlocks

        (Doc.Image { url, description }) :: nextBlocks ->
            (Ui.image [] { src = url, description = description }
                |> View.Figure.figure
                |> View.Figure.view
            )
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.Video videoEmbed) :: nextBlocks ->
            View.VideoEmbed.view videoEmbed
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.CodeBlock { code, language }) :: nextBlocks ->
            (View.CodeBlock.fromBody language code
                |> View.CodeBlock.view
            )
                :: toElmUiInternal sectionDepth nextBlocks

        (Doc.LanguageBreak languageBreak) :: nextBlocks ->
            View.LanguageBreak.view languageBreak
                :: toElmUiInternal sectionDepth nextBlocks

        _ :: nextBlocks ->
            (Doc.plainText "[Block]"
                |> inlineToElmUi
            )
                :: toElmUiInternal sectionDepth nextBlocks

        [] ->
            []



-- List Block (List Block)
-- BlockQuote (List Block)
-- CodeBlock String
-- Image String
-- Separation
-- Video
-- AudioPlayer


inlineToElmUi : Doc.Inline -> Ui.Element msg
inlineToElmUi inline =
    case inline of
        Doc.Text styledText ->
            styledTextToElmUi styledText

        Doc.InlineCode text ->
            View.Inline.setCode text

        Doc.Link { target, inlines } ->
            inlines
                |> List.map styledTextToElmUi
                |> View.Inline.setLink target


styledTextToElmUi : Doc.StyledText -> Ui.Element msg
styledTextToElmUi { text, styles } =
    [ Ui.text text ]
        |> setStyleIf styles.bold View.Inline.setBold
        |> setStyleIf styles.italic View.Inline.setItalic
        |> setStyleIf styles.strikethrough View.Inline.setStrikethrough
        |> Ui.paragraph []


setStyleIf : Bool -> (List (Ui.Element msg) -> Ui.Element msg) -> List (Ui.Element msg) -> List (Ui.Element msg)
setStyleIf cond styler children =
    if cond then
        [ styler children ]

    else
        children


listToElmUi : Int -> Maybe Int -> Doc.ListItem -> List Doc.ListItem -> Ui.Element msg
listToElmUi sectionDepth maybeStartNumber firstItem restItems =
    let
        list =
            (firstItem :: restItems)
                |> List.map
                    (\( firstBlock, restBlocks ) ->
                        (firstBlock :: restBlocks)
                            |> toElmUiInternal sectionDepth
                    )
                |> View.List.fromItems
    in
    case maybeStartNumber of
        Just startNumber ->
            list
                |> View.List.withNumbers startNumber
                |> View.List.view

        Nothing ->
            list
                |> View.List.view


blockQuoteToElmUi : Int -> List Doc.Block -> Ui.Element msg
blockQuoteToElmUi sectionDepth blocks =
    let
        line =
            Ui.el
                [ Ui.width (Ui.px Style.spacing.size1)
                , Ui.height Ui.fill
                , UiBackground.color (Style.color.secondary10 |> Color.toElmUi)
                , Ui.alignLeft
                ]
                Ui.none

        side =
            Ui.el
                [ Ui.width (Ui.px Style.spacing.size6)
                , Ui.height Ui.fill
                ]
                line

        toQuote : Ui.Element msg -> Ui.Element msg
        toQuote content =
            Ui.row [ Ui.width Ui.fill ]
                [ side
                , content
                ]
    in
    blocks
        |> toElmUiInternal sectionDepth
        |> View.Column.setSpaced MSpacing
        |> toQuote
