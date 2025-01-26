module Doc.ElmUi exposing (Config, noConfig, view)

import Custom.Color as Color
import Custom.Element as Ui
import Doc
import Element as Ui
import Element.Background as UiBackground
import Html exposing (Html)
import Html.Attributes
import Sand
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


type alias Config msg =
    { onClick : Maybe (String -> msg)
    , audioPlayerState : Maybe View.AudioPlayer.State
    }


view : Config msg -> List (Doc.Block msg) -> Html msg
view config blocks =
    blocks
        |> toElmUiInternal config 1
        |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } [])
        |> View.Column.setSpaced MSpacing


noConfig : Config msg
noConfig =
    { onClick = Nothing
    , audioPlayerState = Nothing
    }



-- INTERNAL


toElmUiInternal : Config msg -> Int -> List (Doc.Block msg) -> List (Ui.Element msg)
toElmUiInternal config sectionDepth blocks =
    case blocks of
        (Doc.Paragraph inlines) :: nextBlocks ->
            (inlines
                |> List.map (viewInline config.onClick)
                |> View.Paragraph.view
            )
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.OrderedList firstItem restItems) :: nextBlocks ->
            viewList config sectionDepth (Just 1) firstItem restItems
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.UnorderedList firstItem restItems) :: nextBlocks ->
            viewList config sectionDepth Nothing firstItem restItems
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.BlockQuote blockQuoteBlocks) :: nextBlocks ->
            viewBlockQuote config sectionDepth blockQuoteBlocks
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.Section { heading, content }) :: nextBlocks ->
            let
                newSectionDepth =
                    sectionDepth + 1
            in
            ([ heading
                |> List.map (viewInline config.onClick)
                |> View.Heading.view newSectionDepth
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []
             , content
                |> toElmUiInternal config newSectionDepth
                |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } [])
                |> View.Column.setSpaced MSpacing
             ]
                |> View.Column.setSpaced MSpacing
                |> Ui.html
            )
                :: toElmUiInternal config sectionDepth nextBlocks

        Doc.Separation :: nextBlocks ->
            viewSeparation
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.Image { url, description, caption }) :: nextBlocks ->
            (Ui.image [ Ui.centerX ]
                { src = url, description = description }
                |> View.Figure.figure
                |> (if caption /= "" then
                        View.Figure.setCaption caption

                    else
                        identity
                   )
                |> View.Figure.view
            )
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.Video videoEmbed) :: nextBlocks ->
            View.VideoEmbed.view videoEmbed
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.CodeBlock { code, language }) :: nextBlocks ->
            (View.CodeBlock.fromBody language code
                |> View.CodeBlock.view
            )
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.LanguageBreak languageBreak) :: nextBlocks ->
            View.LanguageBreak.view languageBreak
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.AudioPlayer audioPlayer) :: nextBlocks ->
            case config.audioPlayerState of
                Just aps ->
                    View.AudioPlayer.view aps audioPlayer
                        :: toElmUiInternal config sectionDepth nextBlocks

                Nothing ->
                    ([ Html.text "[AudioPlayer state not provided]" ]
                        |> View.Paragraph.view
                    )
                        :: toElmUiInternal config sectionDepth nextBlocks

        [] ->
            []


viewInline : Maybe (String -> msg) -> Doc.Inline -> Html msg
viewInline onClickMaybe inline =
    case inline of
        Doc.Text styledText ->
            viewStyledText styledText

        Doc.InlineCode text ->
            View.Inline.setCode text

        Doc.Link { target, inlines } ->
            (inlines
                |> List.map viewStyledText
            )
                |> View.Inline.setLink onClickMaybe target

        Doc.LineBreak ->
            [ Html.text "\n" ]
                |> Html.span [ Html.Attributes.style "white-space" "pre-wrap" ]


viewStyledText : Doc.StyledText -> Html msg
viewStyledText { text, styles } =
    Html.span
        [ Sand.setAttributeIf styles.bold
            (Html.Attributes.style "font-weight" "bold")
        , Sand.setAttributeIf styles.italic
            (Html.Attributes.style "font-style" "italic")
        , Sand.setAttributeIf styles.strikethrough
            (Html.Attributes.style "text-decoration" "line-through")
        ]
        [ Html.text text ]


viewList : Config msg -> Int -> Maybe Int -> Doc.ListItem msg -> List (Doc.ListItem msg) -> Ui.Element msg
viewList config sectionDepth maybeStartNumber firstItem restItems =
    let
        list =
            (firstItem :: restItems)
                |> List.map
                    (\( firstBlock, restBlocks ) ->
                        (firstBlock :: restBlocks)
                            |> toElmUiInternal config sectionDepth
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


viewBlockQuote : Config msg -> Int -> List (Doc.Block msg) -> Ui.Element msg
viewBlockQuote config sectionDepth blocks =
    let
        line =
            Ui.el
                [ Ui.varWidth Style.spacing.size1
                , Ui.height Ui.fill
                , UiBackground.color (Style.color.primary10 |> Color.toElmUi)
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
        |> toElmUiInternal config sectionDepth
        |> List.map (Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } [])
        |> View.Column.setSpaced MSpacing
        |> Ui.html
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
                , UiBackground.color (Style.color.primary50 |> Color.toElmUi)
                ]
                Ui.none
    in
    Ui.row
        [ Ui.width Ui.fill
        , Ui.varPaddingTop Style.spacing.size5
        , Ui.varPaddingBottom Style.spacing.size5
        ]
        [ blank, rule, blank ]
