module Doc.ElmUi exposing (Config, noConfig, view)

import Color
import Custom.Color as Color
import Doc
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
        |> View.Column.setSpaced MSpacing


noConfig : Config msg
noConfig =
    { onClick = Nothing
    , audioPlayerState = Nothing
    }



-- INTERNAL


toElmUiInternal : Config msg -> Int -> List (Doc.Block msg) -> List (Html msg)
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
             , content
                |> toElmUiInternal config newSectionDepth
                |> View.Column.setSpaced MSpacing
             ]
                |> View.Column.setSpaced MSpacing
            )
                :: toElmUiInternal config sectionDepth nextBlocks

        Doc.Separation :: nextBlocks ->
            viewSeparation
                :: toElmUiInternal config sectionDepth nextBlocks

        (Doc.Image { url, description, caption }) :: nextBlocks ->
            (View.Figure.figure
                (Html.img
                    [ Html.Attributes.src url
                    , Html.Attributes.alt description
                    ]
                    []
                )
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


viewList : Config msg -> Int -> Maybe Int -> Doc.ListItem msg -> List (Doc.ListItem msg) -> Html msg
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


viewBlockQuote : Config msg -> Int -> List (Doc.Block msg) -> Html msg
viewBlockQuote config sectionDepth blocks =
    let
        toQuote : Html msg -> Html msg
        toQuote content =
            Sand.div
                [ Html.Attributes.style "border-left-width" "4px"
                , Html.Attributes.style "border-left-style" "solid"
                , Html.Attributes.style "border-left-color" (Color.toCssString Style.color.primary10)
                , Sand.paddingLeft Sand.L5
                ]
                [ content ]
    in
    blocks
        |> toElmUiInternal config sectionDepth
        |> View.Column.setSpaced MSpacing
        |> toQuote


viewSeparation : Html msg
viewSeparation =
    Html.hr
        [ Sand.marginTop Sand.L6
        , Sand.marginBottom Sand.L6
        , Sand.height Sand.L1
        , Sand.width (Sand.LRaw "100%")
        , Sand.backgroundColor Style.color.primary50
        , Html.Attributes.style "border" "none"
        ]
        []
