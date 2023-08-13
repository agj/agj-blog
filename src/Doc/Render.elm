module Doc.Render exposing (..)

import Doc
import Element as Ui
import View.Column exposing (Spacing(..))
import View.Figure
import View.Heading
import View.Inline
import View.Paragraph


toElmUi : List Doc.Block -> Ui.Element msg
toElmUi blocks =
    blocks
        |> Debug.log "blocks"
        |> toElmUiInternal 1
        |> View.Column.setSpaced MSpacing



-- INTERNAL


toElmUiInternal : Int -> List Doc.Block -> List (Ui.Element msg)
toElmUiInternal sectionDepth blocks =
    let
        _ =
            Debug.log "sectionDepth" sectionDepth
    in
    case blocks of
        (Doc.Paragraph inlines) :: nextBlocks ->
            (inlines
                |> List.map inlineToElmUi
                |> View.Paragraph.view
            )
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
