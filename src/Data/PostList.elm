module Data.PostList exposing (sortByTime, view)

import Custom.List as List
import Data.Category as Category
import Data.Date as Date
import Data.Post as Post
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Time
import Time.Extra


sortByTime : List Post.GlobMatchFrontmatter -> List Post.GlobMatchFrontmatter
sortByTime posts =
    posts
        |> List.sortBy (getTime >> Time.posixToMillis)
        |> List.reverse


view : List Post.GlobMatchFrontmatter -> Html msg
view posts =
    let
        gistsByYearAndMonth : List ( String, List ( Int, List Post.GlobMatchFrontmatter ) )
        gistsByYearAndMonth =
            posts
                |> List.gatherUnder .yearString
                |> List.sortBy Tuple.first
                |> List.reverse
                |> List.map
                    (\( year, yearGists ) ->
                        ( year
                        , yearGists
                            |> List.gatherUnder .monthString
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


getTime : Post.GlobMatchFrontmatter -> Time.Posix
getTime gist =
    case gist.frontmatter.dateTime of
        Just date ->
            date

        Nothing ->
            Time.Extra.partsToPosix
                Time.utc
                { year = gist.year
                , month = gist.month
                , day = gist.frontmatter.dayOfMonth
                , hour = 0
                , minute = 0
                , second = 0
                , millisecond = 0
                }


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
        heading : Html msg
        heading =
            Html.h3 [ class "text-layout-70" ]
                [ Html.text (Date.intToMonthFullName month) ]

        gistsList : List (Html msg)
        gistsList =
            List.map viewGist gists
    in
    Html.div [ class "flex flex-col gap-1" ]
        (heading :: gistsList)


viewGist : Post.GlobMatchFrontmatter -> Html msg
viewGist gist =
    let
        postDayOfMonth : Html msg
        postDayOfMonth =
            Html.div [ class "text-layout-70 min-w-5 tabular-nums" ]
                [ Html.text
                    (gist.frontmatter.dayOfMonth |> String.fromInt |> String.padLeft 2 '0')
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
        [ postDayOfMonth
        , Html.div [] [ postLink, postCategories ]
        ]
