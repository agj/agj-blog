module Data.PostList exposing (view)

import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Post as Post
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List


view : List Category -> List Post.GlobMatchFrontmatter -> List (Html msg)
view categories posts =
    let
        padNumber : Int -> String
        padNumber num =
            num
                |> String.fromInt
                |> String.padLeft 2 '0'

        getDateHour : Post.GlobMatchFrontmatter -> String
        getDateHour gist =
            padNumber gist.frontmatter.date
                ++ padNumber (gist.frontmatter.hour |> Maybe.withDefault 0)

        getTime : Post.GlobMatchFrontmatter -> String
        getTime gist =
            gist.year ++ gist.month ++ getDateHour gist

        gistsByMonth =
            posts
                |> List.gatherEqualsBy (\gist -> gist.year ++ gist.month)
                |> List.sortBy (Tuple.first >> getTime)
                |> List.map
                    (\( firstGist, rest ) ->
                        ( "{year}, {month}"
                            |> String.replace "{year}" firstGist.year
                            |> String.replace "{month}" (Date.monthNumberToFullName (firstGist.month |> String.toInt |> Maybe.withDefault 0))
                        , firstGist
                            :: rest
                            |> List.sortBy getTime
                            |> List.reverse
                        )
                    )
    in
    gistsByMonth
        |> List.map (viewGistMonth categories)
        |> List.foldl (++) []



-- INTERNAL


viewGistMonth : List Category -> ( String, List Post.GlobMatchFrontmatter ) -> List (Html msg)
viewGistMonth categories ( month, gists ) =
    [ Html.p []
        [ Html.strong []
            [ Html.text month
            ]
        ]
    , Html.ul []
        (gists
            |> List.map (viewGist categories)
        )
    ]


viewGist : List Category -> Post.GlobMatchFrontmatter -> Html msg
viewGist categories gist =
    let
        dateText =
            "{date} – "
                |> String.replace "{date}" (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')

        postCategories =
            gist.frontmatter.categories
                |> List.map (Category.get categories)
    in
    Html.li []
        [ Html.text dateText
        , Html.a [ Attr.href (Post.globMatchFrontmatterToUrl gist) ]
            [ Html.strong []
                [ Html.text gist.frontmatter.title ]
            ]
        , Html.small []
            (Html.text " ("
                :: (postCategories
                        |> List.map (Category.toLink [ Attr.class "secondary" ])
                        |> List.intersperse (Html.text ", ")
                   )
                ++ [ Html.text ")" ]
            )
        ]
