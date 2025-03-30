module Data.PostList exposing (sortByTime, view)

import Custom.List as List
import Data.Category as Category
import Data.Date as Date
import Data.Post as Post
import Html exposing (Html)
import Html.Attributes exposing (class, href)


sortByTime : List Post.GlobMatchFrontmatter -> List Post.GlobMatchFrontmatter
sortByTime posts =
    posts
        |> List.sortBy getTime
        |> List.reverse


view : List Post.GlobMatchFrontmatter -> Html msg
view posts =
    let
        gistsByYearAndMonth : List ( String, List ( Int, List Post.GlobMatchFrontmatter ) )
        gistsByYearAndMonth =
            posts
                |> List.gatherUnder .year
                |> List.sortBy Tuple.first
                |> List.reverse
                |> List.map
                    (\( year, yearGists ) ->
                        ( year
                        , yearGists
                            |> List.gatherUnder .month
                            |> List.sortBy Tuple.first
                            |> List.reverse
                            |> List.map
                                (\( month, monthGists ) ->
                                    ( String.toInt month |> Maybe.withDefault 0
                                    , sortByTime monthGists
                                    )
                                )
                        )
                    )
    in
    Html.div [ class "flex flex-col gap-8" ]
        (List.map viewGistYear gistsByYearAndMonth)



-- INTERNAL


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


viewGistYear : ( String, List ( Int, List Post.GlobMatchFrontmatter ) ) -> Html msg
viewGistYear ( year, gistMonths ) =
    let
        heading =
            Html.h2 [ class "text-layout-70 text-2xl" ]
                [ Html.text year ]

        months =
            gistMonths
                |> List.map viewGistMonth
    in
    Html.div [ class "flex flex-col gap-4" ]
        (heading :: months)


viewGistMonth : ( Int, List Post.GlobMatchFrontmatter ) -> Html msg
viewGistMonth ( month, gists ) =
    let
        monthName =
            Date.monthNumberToFullName month

        heading : Html msg
        heading =
            Html.h3 [ class "text-layout-70" ]
                [ Html.text monthName ]

        gistsList : List (Html msg)
        gistsList =
            List.map viewGist gists
    in
    Html.div [ class "flex flex-col gap-1" ]
        (heading :: gistsList)


viewGist : Post.GlobMatchFrontmatter -> Html msg
viewGist gist =
    let
        postDate : Html msg
        postDate =
            Html.div [ class "text-layout-70 min-w-5" ]
                [ Html.text
                    (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')
                ]

        postLink : Html msg
        postLink =
            Html.b []
                [ Html.a [ href (Post.globMatchFrontmatterToUrl gist) ]
                    [ Html.text gist.frontmatter.title ]
                ]

        postCategoryEls : List (Html msg)
        postCategoryEls =
            gist.frontmatter.categories
                |> List.map
                    (\category ->
                        Html.a [ href (Category.toUrl category) ]
                            [ Html.text (Category.getName category) ]
                    )

        postCategories : Html msg
        postCategories =
            Html.span [ class "text-layout-50 text-sm" ]
                (Html.text " ("
                    :: (postCategoryEls |> List.intersperse (Html.text ", "))
                    ++ [ Html.text ")" ]
                )
    in
    Html.div [ class "flex flex-row gap-2" ]
        [ postDate
        , Html.div [] [ postLink, postCategories ]
        ]
