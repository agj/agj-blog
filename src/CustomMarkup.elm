module CustomMarkup exposing (..)

import CustomMarkup.VideoEmbed
import Html exposing (Html)
import Markdown.Html
import Markdown.Renderer


renderer : Markdown.Renderer.Renderer (Html msg)
renderer =
    let
        defRenderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    { defRenderer
        | html =
            Markdown.Html.oneOf
                [ CustomMarkup.VideoEmbed.renderer
                    |> Markdown.Html.map
                        (\result ->
                            case result of
                                Ok videoEmbed ->
                                    CustomMarkup.VideoEmbed.toHtml videoEmbed

                                Err err ->
                                    \_ -> Html.div [] (renderErrorMessage err)
                        )
                ]
    }


renderErrorMessage : String -> List (Html msg)
renderErrorMessage error =
    [ Html.p []
        [ Html.text "Parsing error:"
        ]
    , Html.pre []
        [ Html.code [] [ Html.text error ]
        ]
    ]
