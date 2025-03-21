module View.CodeBlock exposing
    ( CodeBlock
    , fromBody
    , styles
    , view
    )

import Html exposing (Html)
import Html.Attributes
import SyntaxHighlight


type CodeBlock
    = CodeBlock
        { body : String
        , language : Maybe String
        }


fromBody : Maybe String -> String -> CodeBlock
fromBody language body =
    CodeBlock { body = body, language = language }


view : CodeBlock -> Html msg
view (CodeBlock { body, language }) =
    let
        highlighter =
            case language of
                Just "elm" ->
                    SyntaxHighlight.elm

                Just "js" ->
                    SyntaxHighlight.javascript

                Just "json" ->
                    SyntaxHighlight.json

                Just "html" ->
                    SyntaxHighlight.xml

                Just "xml" ->
                    SyntaxHighlight.xml

                Just "css" ->
                    SyntaxHighlight.css

                Just "py" ->
                    SyntaxHighlight.python

                Just "sql" ->
                    SyntaxHighlight.sql

                Just "nix" ->
                    SyntaxHighlight.nix

                _ ->
                    SyntaxHighlight.noLang
    in
    highlighter body
        |> Result.map (SyntaxHighlight.toBlockHtml (Just 1))
        |> Result.withDefault
            (Html.div []
                [ Html.text "[COULDN'T PARSE CODE BLOCK]" ]
            )


styles : Html msg
styles =
    let
        generalStyles =
            Html.node "style"
                []
                [ Html.text css ]

        themeStyles =
            SyntaxHighlight.useTheme SyntaxHighlight.gitHub
    in
    Html.div [ Html.Attributes.hidden True ]
        [ generalStyles
        , themeStyles
        ]



-- INTERNAL


css : String
css =
    """
    pre.elmsh {
        padding: 10px;
        margin: 0;
        text-align: left;
        overflow: auto;
    }
    code.elmsh {
        padding: 0;
    }
    .elmsh-line:before {
        content: attr(data-elmsh-lc);
        display: inline-block;
        text-align: right;
        width: 40px;
        padding: 0 20px 0 0;
        opacity: 0.3;
    }
    """
