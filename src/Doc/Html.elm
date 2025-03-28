module Doc.Html exposing (Config, noConfig, view)

import Custom.Html.Attributes
import Doc
import Html exposing (Html)
import Html.Attributes exposing (class, classList, href)
import Html.Events
import View.AudioPlayer
import View.CodeBlock
import View.Figure
import View.Heading
import View.Inline
import View.LanguageBreak
import View.List
import View.VideoEmbed


type alias Config msg =
    { onClick : Maybe (String -> msg)
    , audioPlayerState : Maybe View.AudioPlayer.State
    }


view : Config msg -> List (Doc.Block msg) -> Html msg
view config blocks =
    Html.div [ class "flex flex-col gap-4" ]
        (viewInternal config 1 blocks)


noConfig : Config msg
noConfig =
    { onClick = Nothing
    , audioPlayerState = Nothing
    }



-- INTERNAL


viewInternal : Config msg -> Int -> List (Doc.Block msg) -> List (Html msg)
viewInternal config sectionDepth blocks =
    case blocks of
        (Doc.Paragraph inlines) :: nextBlocks ->
            (inlines
                |> List.map (viewInline config.onClick)
                |> paragraph
            )
                :: viewInternal config sectionDepth nextBlocks

        (Doc.OrderedList firstItem restItems) :: nextBlocks ->
            viewList config sectionDepth (Just 1) firstItem restItems
                :: viewInternal config sectionDepth nextBlocks

        (Doc.UnorderedList firstItem restItems) :: nextBlocks ->
            viewList config sectionDepth Nothing firstItem restItems
                :: viewInternal config sectionDepth nextBlocks

        (Doc.BlockQuote blockQuoteBlocks) :: nextBlocks ->
            viewBlockQuote config sectionDepth blockQuoteBlocks
                :: viewInternal config sectionDepth nextBlocks

        (Doc.Section { heading, content }) :: nextBlocks ->
            let
                newSectionDepth =
                    sectionDepth + 1
            in
            Html.div [ class "flex w-full flex-col gap-4" ]
                [ heading
                    |> List.map (viewInline config.onClick)
                    |> View.Heading.view newSectionDepth
                , Html.div [ class "flex w-full flex-col gap-4" ]
                    (viewInternal config newSectionDepth content)
                ]
                :: viewInternal config sectionDepth nextBlocks

        Doc.Separation :: nextBlocks ->
            viewSeparation
                :: viewInternal config sectionDepth nextBlocks

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
                :: viewInternal config sectionDepth nextBlocks

        (Doc.Video videoEmbed) :: nextBlocks ->
            View.VideoEmbed.view videoEmbed
                :: viewInternal config sectionDepth nextBlocks

        (Doc.CodeBlock { code, language }) :: nextBlocks ->
            (View.CodeBlock.fromBody language code
                |> View.CodeBlock.view
            )
                :: viewInternal config sectionDepth nextBlocks

        (Doc.LanguageBreak languageBreak) :: nextBlocks ->
            View.LanguageBreak.view languageBreak
                :: viewInternal config sectionDepth nextBlocks

        (Doc.AudioPlayer audioPlayer) :: nextBlocks ->
            case config.audioPlayerState of
                Just aps ->
                    View.AudioPlayer.view aps audioPlayer
                        :: viewInternal config sectionDepth nextBlocks

                Nothing ->
                    ([ Html.text "[AudioPlayer state not provided]" ]
                        |> paragraph
                    )
                        :: viewInternal config sectionDepth nextBlocks

        [] ->
            []


viewInline : Maybe (String -> msg) -> Doc.Inline -> Html msg
viewInline onClickMaybe inline =
    case inline of
        Doc.Text styledText ->
            viewStyledText styledText

        Doc.InlineCode text ->
            View.Inline.code text

        Doc.Link { target, inlines } ->
            Html.a
                [ href target
                , case onClickMaybe of
                    Just msg ->
                        Html.Events.onClick (msg target)

                    Nothing ->
                        Custom.Html.Attributes.none
                ]
                (List.map viewStyledText inlines)

        Doc.LineBreak ->
            Html.span [ class "whitespace-pre-wrap" ]
                [ Html.text "\n" ]


viewStyledText : Doc.StyledText -> Html msg
viewStyledText { text, styles } =
    Html.span
        [ classList
            [ ( "font-bold", styles.bold )
            , ( "italic", styles.italic )
            , ( "line-through", styles.strikethrough )
            ]
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
                            |> viewInternal config sectionDepth
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
    Html.div [ class "border-layout-20 flex flex-col border-l-[1rem] border-solid pl-6" ]
        [ Html.div [ class "flex flex-col gap-4" ]
            (viewInternal config sectionDepth blocks)
        ]


viewSeparation : Html msg
viewSeparation =
    Html.hr [ class "bg-layout-20 my-6 h-1 w-full border-0" ]
        []


paragraph : List (Html msg) -> Html msg
paragraph inlines =
    Html.p [ class "w-full text-base" ]
        inlines
