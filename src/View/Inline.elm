module View.Inline exposing (code)

import Html exposing (Html)
import Html.Attributes exposing (class)


code : String -> Html msg
code codeString =
    Html.span [ class "bg-layout-20 text-size-mono whitespace-pre-wrap rounded box-decoration-clone px-1 py-1 font-mono" ]
        [ Html.text codeString ]
