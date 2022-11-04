module Custom.List exposing (..)


memberOf : List a -> a -> Bool
memberOf list item =
    List.member item list
