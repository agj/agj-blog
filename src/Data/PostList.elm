module Data.PostList exposing (view)

import Custom.List as List
import Data.Category as Category exposing (Category)
import Data.Date as Date
import Data.Post as Post
import Element as Ui
import List.Extra as List
import View.Column exposing (Spacing(..))
import View.Heading
import View.Inline
import View.List
import View.Paragraph


view : List Post.GlobMatchFrontmatter -> Ui.Element msg
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
        |> View.Column.setSpaced MSpacing



-- INTERNAL


viewGistYear : ( String, List ( String, List Post.GlobMatchFrontmatter ) ) -> Ui.Element msg
viewGistYear ( year, gistMonths ) =
    let
        heading =
            [ Ui.text year ]
                |> View.Heading.view 2

        months =
            gistMonths
                |> List.map viewGistMonth
    in
    (heading :: months)
        |> View.Column.setSpaced MSpacing


viewGistMonth : ( String, List Post.GlobMatchFrontmatter ) -> Ui.Element msg
viewGistMonth ( month, gists ) =
    let
        monthName =
            Date.monthNumberToFullName (String.toInt month |> Maybe.withDefault 0)

        heading =
            [ Ui.text monthName ]
                |> View.Heading.view 3

        gistsList =
            gists
                |> List.map (viewGist >> List.singleton)
                |> View.List.fromItems
                |> View.List.view
    in
    [ heading, gistsList ]
        |> View.Column.setSpaced MSpacing


viewGist : Post.GlobMatchFrontmatter -> Ui.Element msg
viewGist gist =
    let
        postDate =
            "{date} – "
                |> String.replace "{date}" (gist.frontmatter.date |> String.fromInt |> String.padLeft 2 '0')
                |> Ui.text

        postLink =
            [ Ui.text gist.frontmatter.title ]
                |> View.Inline.setLink (Post.globMatchFrontmatterToUrl gist)
                |> List.singleton
                |> View.Inline.setBold

        postCategoryEls =
            gist.frontmatter.categories
                |> List.map
                    (\category ->
                        [ Ui.text (Category.getName category) ]
                            |> View.Inline.setLink (Category.toUrl category)
                    )

        postCategories =
            Ui.text " ("
                :: (postCategoryEls |> List.intersperse (Ui.text ", "))
                ++ [ Ui.text ")" ]
    in
    [ postDate, postLink ]
        ++ postCategories
        |> View.Paragraph.view
