module View.TextBlock exposing
    ( heading1
    , heading2
    , heading3
    , heading4
    , heading5
    , heading6
    , paragraph
    , view
    )

import Custom.Color as Color
import Element as Ui
import Element.Font as UiFont
import Element.Region as UiRegion
import Html.Attributes
import Style


type TextBlock msg
    = TextBlock
        { type_ : TextBlockType
        , children : List (Ui.Element msg)
        }


type TextBlockType
    = Paragraph
    | Heading Int


paragraph : List (Ui.Element msg) -> TextBlock msg
paragraph children =
    TextBlock
        { type_ = Paragraph
        , children = children
        }


heading1 =
    heading 1


heading2 =
    heading 2


heading3 =
    heading 3


heading4 =
    heading 4


heading5 =
    heading 5


heading6 =
    heading 6



-- VIEW


view : TextBlock msg -> Ui.Element msg
view (TextBlock tb) =
    case tb.type_ of
        Paragraph ->
            Ui.paragraph
                (baseStyles
                    ++ [ Ui.paddingXY 0 Style.spacing.size3
                       ]
                )
                tb.children

        Heading level ->
            Ui.paragraph
                (baseStyles
                    ++ [ UiRegion.heading level
                       , Ui.paddingEach
                            { top = Style.spacing.size4
                            , bottom = Style.spacing.size3
                            , left = 0
                            , right = 0
                            }
                       ]
                    ++ headingTextStyles level
                )
                tb.children



-- INTERNAL


heading : Int -> List (Ui.Element msg) -> TextBlock msg
heading level children =
    TextBlock
        { type_ = Heading level
        , children = children
        }


baseStyles : List (Ui.Attribute msg)
baseStyles =
    [ Ui.paddingXY 0 10
    , UiFont.color (Color.toElmUi Style.color.layout)
    , UiFont.size Style.textSize.m
    , Ui.spacing (Style.interline.m Style.textSize.m)
    ]


headingTextStyles : Int -> List (Ui.Attribute msg)
headingTextStyles headingLevel =
    case headingLevel of
        1 ->
            [ UiFont.size Style.textSize.xxl ]

        2 ->
            [ UiFont.size Style.textSize.xl
            , Ui.htmlAttribute (Html.Attributes.style "text-transform" "uppercase")
            ]

        3 ->
            [ UiFont.size Style.textSize.xl ]

        4 ->
            [ UiFont.size Style.textSize.l
            , Ui.htmlAttribute (Html.Attributes.style "text-transform" "uppercase")
            ]

        5 ->
            [ UiFont.size Style.textSize.l ]

        6 ->
            [ UiFont.size Style.textSize.m
            , UiFont.bold
            ]

        _ ->
            [ UiFont.size Style.textSize.m ]
