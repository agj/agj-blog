module View.Heading exposing (..)

import Css
import Custom.Element as Ui
import Element as Ui
import Element.Font as UiFont
import Element.Region as UiRegion
import Html exposing (Html)
import Html.Attributes
import Style


view : Int -> List (Html msg) -> Ui.Element msg
view level content =
    let
        normalizedLevel =
            max 1 level

        basePadding =
            Style.blockPadding fontSize Style.interline.s

        baseStyles =
            [ Ui.varFontSize fontSize
            , Ui.varLineSpacing (Style.interline.s fontSize)
            , Ui.width Ui.fill
            , UiRegion.heading normalizedLevel
            , Ui.varPaddingTop (Css.CalcAddition basePadding Style.spacing.size5)
            , Ui.varPaddingBottom basePadding
            ]

        ( fontSize, styles, prepend ) =
            case normalizedLevel of
                1 ->
                    ( Style.textSize.xxl
                    , [ UiFont.bold ]
                    , Nothing
                    )

                2 ->
                    ( Style.textSize.xl
                    , [ UiFont.bold ]
                    , Nothing
                    )

                3 ->
                    ( Style.textSize.l
                    , [ UiFont.bold ]
                    , Nothing
                    )

                4 ->
                    ( Style.textSize.l
                    , []
                    , Nothing
                    )

                _ ->
                    ( Style.textSize.l
                    , []
                    , Just (String.repeat (normalizedLevel - 4) "▹")
                    )

        prependEl : Html msg
        prependEl =
            case prepend of
                Just text ->
                    Html.span
                        [ Html.Attributes.attribute "aria-hidden" "true"
                        , Html.Attributes.style "user-select" "none"
                        ]
                        [ Html.text (text ++ " ") ]

                Nothing ->
                    Html.text ""
    in
    Ui.paragraph (baseStyles ++ styles)
        (prependEl :: content |> List.map Ui.html)
