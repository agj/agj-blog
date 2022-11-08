module Data.PostList exposing (view)

import Custom.List as List
import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Post as Post
import Html exposing (Html)
import Html.Attributes as Attr
import List.Extra as List


view : List Post.GlobMatchFrontmatter -> List (Html msg)
view posts =
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

        gistsByYearAndMonth : List ( String, List ( String, List Post.GlobMatchFrontmatter ) )
        gistsByYearAndMonth =
            posts
                |> List.gatherUnder .year
                |> List.sortBy Tuple.first
                |> List.map (Tuple.mapSecond (List.gatherUnder .month >> List.sortBy Tuple.first >> List.reverse))
                |> List.map (Tuple.mapSecond (List.map (Tuple.mapSecond (List.sortBy getTime >> List.reverse))))
    in
    gistsByYearAndMonth
        |> List.map viewGistYear
        |> List.foldl (++) []



-- INTERNAL


viewGistYear : ( String, List ( String, List Post.GlobMatchFrontmatter ) ) -> List (Html msg)
viewGistYear ( year, gistMonths ) =
    Html.h3 [] [ Html.text year ]
        :: (gistMonths
                |> List.andThen viewGistMonth
           )


viewGistMonth : ( String, List Post.GlobMatchFrontmatter ) -> List (Html msg)
viewGistMonth ( month, gists ) =
    [ Html.p []
        [ Html.strong []
            [ Html.text (Date.monthNumberToFullName (String.toInt month |> Maybe.withDefault 0))
            ]
        ]
    , Html.ul []
        (gists
            |> List.map viewGist
        )
    ]


viewGist : Post.GlobMatchFrontmatter -> Html msg
viewGist gist =
    let
        dateText =
            "{date} – "
                |> String.replace "{date}" (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')

        postCategories =
            gist.frontmatter.categories
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
