module Doc.Render exposing (..)

import Doc
import Element as Ui
import View.Column exposing (Spacing(..))
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

        _ ->
            Doc.plainText ""
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
        Doc.Text { text, styles } ->
            Ui.text text

        Doc.InlineCode text ->
            View.Inline.setCode text

        Doc.Link { target, text, styles } ->
            Ui.text text
