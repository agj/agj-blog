module View exposing (View, map, placeholder)

import Element as Ui


type alias View msg =
    { title : String
    , body : Ui.Element msg
    }


map : (msg1 -> msg2) -> View msg1 -> View msg2
map fn doc =
    { title = doc.title
    , body = Ui.map fn doc.body
    }


placeholder : String -> View msg
placeholder moduleName =
    { title = "Placeholder - " ++ moduleName
    , body = Ui.text moduleName
    }
