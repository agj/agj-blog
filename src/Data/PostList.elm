module Data.PostList exposing (view)

import Custom.List as List
import Data.Category as Category
import Data.Date as Date
import Data.Post as Post
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import View.Heading
import View.List


view : List Post.GlobMatchFrontmatter -> Html msg
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
                                    , monthGists
                                        |> List.sortBy getTime
                                        |> List.reverse
                                    )
                                )
                        )
                    )
    in
    Html.div [ class "flex flex-col gap-4" ]
        (List.map viewGistYear gistsByYearAndMonth)



-- INTERNAL


viewGistYear : ( String, List ( Int, List Post.GlobMatchFrontmatter ) ) -> Html msg
viewGistYear ( year, gistMonths ) =
    let
        heading =
            [ Html.text year ]
                |> View.Heading.view 2

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
            [ Html.text monthName ]
                |> View.Heading.view 3

        gistsList : Html msg
        gistsList =
            gists
                |> List.map (viewGist >> List.singleton)
                |> View.List.fromItems
                |> View.List.view
    in
    Html.div [ class "flex flex-col gap-4" ]
        [ heading, gistsList ]


viewGist : Post.GlobMatchFrontmatter -> Html msg
viewGist gist =
    let
        postDate : Html msg
        postDate =
            "{date} – "
                |> String.replace "{date}" (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')
                |> Html.text

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

        postCategories : List (Html msg)
        postCategories =
            Html.text " ("
                :: (postCategoryEls |> List.intersperse (Html.text ", "))
                ++ [ Html.text ")" ]
    in
    Html.div []
        ([ postDate, postLink ]
            ++ postCategories
        )
