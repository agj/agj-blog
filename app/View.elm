module View exposing (View, map)

import Element as Ui


type alias View msg =
    { title : String
    , body : Ui.Element msg
    }



-- MODIFICATION


map : (msg1 -> msg2) -> View msg1 -> View msg2
map fn doc =
    { title = doc.title
    , body = Ui.map fn doc.body
    }
