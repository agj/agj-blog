module Doc.Render exposing (..)

import Custom.Color as Color
import Custom.Element as Ui
import Doc
import Element as Ui
import Element.Background as UiBackground
import Html
import Html.Attributes
import Style
import View.AudioPlayer
import View.CodeBlock
import View.Column exposing (Spacing(..))
import View.Figure
import View.Heading
import View.Inline
import View.LanguageBreak
import View.List
import View.Paragraph
import View.VideoEmbed


type alias State =
    { audioPlayerState : View.AudioPlayer.State
    }


toElmUi : Maybe State -> List (Doc.Block msg) -> Ui.Element msg
toElmUi state blocks =
    blocks
        |> toElmUiInternal state 1
        |> View.Column.setSpaced MSpacing



-- INTERNAL


toElmUiInternal : Maybe State -> Int -> List (Doc.Block msg) -> List (Ui.Element msg)
toElmUiInternal state sectionDepth blocks =
    case blocks of
        (Doc.Paragraph inlines) :: nextBlocks ->
            (inlines
                |> List.map viewInline
                |> View.Paragraph.view
            )
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.OrderedList firstItem restItems) :: nextBlocks ->
            viewList state sectionDepth (Just 1) firstItem restItems
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.UnorderedList firstItem restItems) :: nextBlocks ->
            viewList state sectionDepth Nothing firstItem restItems
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.BlockQuote blockQuoteBlocks) :: nextBlocks ->
            viewBlockQuote state sectionDepth blockQuoteBlocks
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.Section { heading, content }) :: nextBlocks ->
            let
                newSectionDepth =
                    sectionDepth + 1
            in
            ([ heading
                |> List.map viewInline
                |> View.Heading.view newSectionDepth
             , content
                |> toElmUiInternal state newSectionDepth
                |> View.Column.setSpaced MSpacing
             ]
                |> View.Column.setSpaced MSpacing
            )
                :: toElmUiInternal state newSectionDepth nextBlocks

        Doc.Separation :: nextBlocks ->
            viewSeparation
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.Image { url, description }) :: nextBlocks ->
            (Ui.image [] { src = url, description = description }
                |> View.Figure.figure
                |> View.Figure.view
            )
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.Video videoEmbed) :: nextBlocks ->
            View.VideoEmbed.view videoEmbed
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.CodeBlock { code, language }) :: nextBlocks ->
            (View.CodeBlock.fromBody language code
                |> View.CodeBlock.view
            )
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.LanguageBreak languageBreak) :: nextBlocks ->
            View.LanguageBreak.view languageBreak
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.AudioPlayer audioPlayer) :: nextBlocks ->
            case state of
                Just { audioPlayerState } ->
                    View.AudioPlayer.view audioPlayerState audioPlayer
                        :: toElmUiInternal state sectionDepth nextBlocks

                Nothing ->
                    ([ Ui.text "[AudioPlayer state not provided]" ]
                        |> View.Paragraph.view
                    )
                        :: toElmUiInternal state sectionDepth nextBlocks

        [] ->
            []


viewInline : Doc.Inline -> Ui.Element msg
viewInline inline =
    case inline of
        Doc.Text styledText ->
            viewStyledText styledText

        Doc.InlineCode text ->
            View.Inline.setCode text

        Doc.Link { target, inlines } ->
            inlines
                |> List.map viewStyledText
                |> View.Inline.setLink target

        Doc.LineBreak ->
            [ Html.text "\n" ]
                |> Html.span [ Html.Attributes.style "white-space" "pre-wrap" ]
                |> Ui.html


viewStyledText : Doc.StyledText -> Ui.Element msg
viewStyledText { text, styles } =
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


viewList : Maybe State -> Int -> Maybe Int -> Doc.ListItem msg -> List (Doc.ListItem msg) -> Ui.Element msg
viewList state sectionDepth maybeStartNumber firstItem restItems =
    let
        list =
            (firstItem :: restItems)
                |> List.map
                    (\( firstBlock, restBlocks ) ->
                        (firstBlock :: restBlocks)
                            |> toElmUiInternal state sectionDepth
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


viewBlockQuote : Maybe State -> Int -> List (Doc.Block msg) -> Ui.Element msg
viewBlockQuote state sectionDepth blocks =
    let
        line =
            Ui.el
                [ Ui.varWidth Style.spacing.size1
                , Ui.height Ui.fill
                , UiBackground.color (Style.color.secondary10 |> Color.toElmUi)
                , Ui.alignLeft
                ]
                Ui.none

        side =
            Ui.el
                [ Ui.varWidth Style.spacing.size6
                , Ui.varWidthFix
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
        |> toElmUiInternal state sectionDepth
        |> View.Column.setSpaced MSpacing
        |> toQuote


viewSeparation : Ui.Element msg
viewSeparation =
    let
        blank =
            Ui.el [ Ui.width (Ui.fillPortion 1) ]
                Ui.none

        rule =
            Ui.el
                [ Ui.width (Ui.fillPortion 1)
                , Ui.height (Ui.px 1)
                , UiBackground.color (Style.color.secondary50 |> Color.toElmUi)
                ]
                Ui.none
    in
    Ui.row
        [ Ui.width Ui.fill
        , Ui.varPaddingTop Style.spacing.size5
        , Ui.varPaddingBottom Style.spacing.size5
        ]
        [ blank, rule, blank ]
