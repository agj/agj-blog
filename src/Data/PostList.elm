module Data.PostList exposing (view)

import Custom.List as List
import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Post as Post
import Element as Ui
import Html exposing (Html)
import List.Extra as List
import View.Column exposing (Spacing(..))
import View.Heading
import View.Inline
import View.List
import View.Paragraph


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
    gistsByYearAndMonth
        |> List.map viewGistYear
        |> View.Column.setSpaced MSpacing



-- INTERNAL


viewGistYear : ( String, List ( Int, List Post.GlobMatchFrontmatter ) ) -> Html msg
viewGistYear ( year, gistMonths ) =
    let
        heading =
            [ Html.text year ]
                |> View.Heading.view 2
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []

        months =
            gistMonths
                |> List.map viewGistMonth
    in
    (heading :: months)
        |> View.Column.setSpaced MSpacing


viewGistMonth : ( Int, List Post.GlobMatchFrontmatter ) -> Html msg
viewGistMonth ( month, gists ) =
    let
        monthName =
            Date.monthNumberToFullName month

        heading : Html msg
        heading =
            [ Html.text monthName ]
                |> View.Heading.view 3
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []

        gistsList : Html msg
        gistsList =
            gists
                |> List.map (viewGist >> List.singleton)
                |> View.List.fromItems
                |> View.List.view
                |> Ui.layoutWith { options = [ Ui.noStaticStyleSheet ] } []
    in
    [ heading, gistsList ]
        |> View.Column.setSpaced MSpacing


viewGist : Post.GlobMatchFrontmatter -> Ui.Element msg
viewGist gist =
    let
        postDate =
            "{date} – "
                |> String.replace "{date}" (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')
                |> Html.text

        postLink =
            [ Html.text gist.frontmatter.title ]
                |> View.Inline.setLink Nothing (Post.globMatchFrontmatterToUrl gist)
                |> List.singleton
                |> Html.b []

        postCategoryEls =
            gist.frontmatter.categories
                |> List.map
                    (\category ->
                        [ Html.text (Category.getName category) ]
                            |> View.Inline.setLink Nothing (Category.toUrl category)
                    )

        postCategories =
            Html.text " ("
                :: (postCategoryEls |> List.intersperse (Html.text ", "))
                ++ [ Html.text ")" ]
    in
    [ postDate, postLink ]
        ++ postCategories
        |> View.Paragraph.view
