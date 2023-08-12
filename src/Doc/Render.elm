module Doc.Render exposing (..)

import Doc
import Element as Ui
import View.Column exposing (Spacing(..))
import View.Figure
import View.Inline
import View.Paragraph


toElmUi : List Doc.Block -> Ui.Element msg
toElmUi blocks =
    blocks
        |> List.map blockToElmUi
        |> View.Column.setSpaced MSpacing


blockToElmUi : Doc.Block -> Ui.Element msg
blockToElmUi block =
    case block of
        Doc.Paragraph inlines ->
            inlines
                |> List.map inlineToElmUi
                |> View.Paragraph.view

        Doc.Image { url, description } ->
            Ui.image [] { src = url, description = description }
                |> View.Figure.figure
                |> View.Figure.view

        _ ->
            Doc.plainText "[Block]"
                |> inlineToElmUi



-- Section { heading : List Inline, content : List Block }
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
