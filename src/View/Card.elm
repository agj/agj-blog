module View.Card exposing (view)

import Html exposing (Html)
import Html.Attributes exposing (class)
import Html.Extra


view : { title : Maybe (Html msg), content : Html msg } -> Html msg
view { title, content } =
    Html.section [ class "bg-layout-20 flex flex-col gap-2 rounded-md p-2" ]
        [ case title of
            Just title_ ->
                Html.h1 [ class "text-layout-50 text-xs font-bold uppercase tracking-wider" ]
                    [ title_ ]

            Nothing ->
                Html.Extra.nothing
        , content
        ]
