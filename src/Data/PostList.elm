module Data.PostList exposing (sortByTime, viewGists)

import Custom.Int as Int
import Custom.List as List
import Data.Category as Category
import Data.Date as Date
import Data.Post as Post exposing (Post, PostGist)
import Date
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Time


sortGistsByTime : List PostGist -> List PostGist
sortGistsByTime posts =
    posts
        |> List.sortBy (.dateTime >> Time.posixToMillis)
        |> List.reverse


sortByTime : List Post -> List Post
sortByTime posts =
    posts
        |> List.sortBy (.gist >> .dateTime >> Time.posixToMillis)
        |> List.reverse


viewGists : List PostGist -> Html msg
viewGists posts =
    let
        postsByYearAndMonth : List ( Int, List ( Int, List PostGist ) )
        postsByYearAndMonth =
            posts
                |> List.gatherUnder (.date >> Date.year)
                |> List.sortBy Tuple.first
                |> List.reverse
                |> List.map
                    (\( year, yearPosts ) ->
                        ( year
                        , yearPosts
                            |> List.gatherUnder (.date >> Date.monthNumber)
                            |> List.sortBy Tuple.first
                            |> List.reverse
                            |> List.map
                                (\( month, monthPosts ) ->
                                    ( month
                                    , sortGistsByTime monthPosts
                                    )
                                )
                        )
                    )
    in
    Html.div [ class "flex flex-col gap-8" ]
        (List.map viewPostYear postsByYearAndMonth)



-- INTERNAL


viewPostYear : ( Int, List ( Int, List PostGist ) ) -> Html msg
viewPostYear ( year, postMonths ) =
    let
        heading =
            Html.h2 [ class "text-layout-70 text-2xl" ]
                [ Html.text (Int.padLeft 4 year) ]

        months =
            postMonths
                |> List.map viewPostMonth
    in
    Html.div [ class "flex flex-col gap-4" ]
        (heading :: months)


viewPostMonth : ( Int, List PostGist ) -> Html msg
viewPostMonth ( month, posts ) =
    let
        heading : Html msg
        heading =
            Html.h3 [ class "text-layout-70" ]
                [ Html.text (Date.intToMonthFullName month) ]

        gistsList : List (Html msg)
        gistsList =
            List.map viewPost posts
    in
    Html.div [ class "flex flex-col gap-1" ]
        (heading :: gistsList)


viewPost : PostGist -> Html msg
viewPost post =
    let
        postDayOfMonth : Html msg
        postDayOfMonth =
            Html.div [ class "text-layout-70 min-w-5 tabular-nums" ]
                [ Html.text (post.date |> Date.day |> Int.padLeft 2)
                ]

        postLink : Html msg
        postLink =
            Html.b []
                [ Html.a [ href (Post.gistToUrl post) ]
                    [ Html.text post.title ]
                ]

        postCategoryEls : List (Html msg)
        postCategoryEls =
            post.categories
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
        [ postDayOfMonth
        , Html.div [] [ postLink, postCategories ]
        ]
