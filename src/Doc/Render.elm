module Doc.Render exposing (..)

import Custom.Color as Color
import Doc
import Element as Ui
import Element.Background as UiBackground
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
                |> List.map inlineToElmUi
                |> View.Paragraph.view
            )
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.OrderedList firstItem restItems) :: nextBlocks ->
            listToElmUi state sectionDepth (Just 1) firstItem restItems
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.UnorderedList firstItem restItems) :: nextBlocks ->
            listToElmUi state sectionDepth Nothing firstItem restItems
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.BlockQuote blockQuoteBlocks) :: nextBlocks ->
            blockQuoteToElmUi state sectionDepth blockQuoteBlocks
                :: toElmUiInternal state sectionDepth nextBlocks

        (Doc.Section { heading, content }) :: nextBlocks ->
            let
                newSectionDepth =
                    sectionDepth + 1
            in
            ([ heading
                |> List.map inlineToElmUi
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


listToElmUi : Maybe State -> Int -> Maybe Int -> Doc.ListItem msg -> List (Doc.ListItem msg) -> Ui.Element msg
listToElmUi state sectionDepth maybeStartNumber firstItem restItems =
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


blockQuoteToElmUi : Maybe State -> Int -> List (Doc.Block msg) -> Ui.Element msg
blockQuoteToElmUi state sectionDepth blocks =
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
        , Ui.paddingXY 0 Style.spacing.size5
        ]
        [ blank, rule, blank ]
