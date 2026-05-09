module Doc exposing (..)

import View.AudioPlayer
import View.LanguageBreak
import View.VideoEmbed


type Inline
    = Text Text
    | Link { target : String, inlines : List Text }
    | LineBreak


type Block msg
    = Paragraph (List Inline)
    | Section { heading : List Inline, content : List (Block msg) }
    | UnorderedList (ListItem msg) (List (ListItem msg))
    | OrderedList (ListItem msg) (List (ListItem msg))
    | BlockQuote (List (Block msg))
    | CodeBlock { language : Maybe String, code : String }
    | Image { url : String, description : String, caption : String }
    | Separation
    | Video View.VideoEmbed.VideoEmbed
    | AudioPlayer (View.AudioPlayer.AudioPlayerWithConfig msg)
    | LanguageBreak View.LanguageBreak.LanguageBreak


type Text
    = StyledText { text : String, styles : Styles }
    | InlineCode String


type alias Styles =
    { bold : Bool
    , italic : Bool
    , strikethrough : Bool
    }


type alias ListItem msg =
    ( Block msg, List (Block msg) )


plainText : String -> Inline
plainText text =
    Text (StyledText { text = text, styles = emptyStyles })


inlineCode : String -> Inline
inlineCode text =
    Text (InlineCode text)


setBold : Inline -> Inline
setBold =
    mapStyles (\styles -> { styles | bold = True })


setItalic : Inline -> Inline
setItalic =
    mapStyles (\styles -> { styles | italic = True })


setStrikethrough : Inline -> Inline
setStrikethrough =
    mapStyles (\styles -> { styles | strikethrough = True })


toLink : String -> List Inline -> Inline
toLink target inlines =
    let
        styledTexts =
            inlines
                |> List.filterMap
                    (\inline ->
                        case inline of
                            Text text ->
                                Just [ text ]

                            Link l ->
                                Just l.inlines

                            LineBreak ->
                                Nothing
                    )
                |> List.concat
    in
    Link { target = target, inlines = styledTexts }


mapStyles : (Styles -> Styles) -> Inline -> Inline
mapStyles mapper inline =
    case inline of
        Text text ->
            Text (mapStyledTextStyles mapper text)

        Link ({ inlines } as config) ->
            Link { config | inlines = inlines |> List.map (mapStyledTextStyles mapper) }

        LineBreak ->
            inline


mapStyledTextStyles : (Styles -> Styles) -> Text -> Text
mapStyledTextStyles mapper text =
    case text of
        StyledText styledText ->
            StyledText { styledText | styles = mapper styledText.styles }

        InlineCode _ ->
            text


emptyStyles : Styles
emptyStyles =
    { bold = False
    , italic = False
    , strikethrough = False
    }
