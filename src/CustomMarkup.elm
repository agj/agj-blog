module CustomMarkup exposing (..)

import CustomMarkup.LanguageBreak
import CustomMarkup.VideoEmbed
import Html exposing (Html)
import Markdown.Html
import Markdown.Renderer
import Result.Extra as Result


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
                    |> resultToHtml CustomMarkup.VideoEmbed.toHtml
                , CustomMarkup.LanguageBreak.renderer
                    |> resultToHtml CustomMarkup.LanguageBreak.toHtml
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



-- INTERNAL


resultToHtml :
    (a -> List (Html msg) -> Html msg)
    -> Markdown.Html.Renderer (Result String a)
    -> Markdown.Html.Renderer (List (Html msg) -> Html msg)
resultToHtml toHtml resultRenderer =
    resultRenderer
        |> Markdown.Html.map
            (Result.mapBoth
                (\err _ -> Html.div [] (renderErrorMessage err))
                toHtml
            )
        |> Markdown.Html.map Result.merge
