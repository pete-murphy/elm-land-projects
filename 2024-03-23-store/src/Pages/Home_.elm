module Pages.Home_ exposing (Model, Msg, page, view, viewAuthors, viewPosts)

import Accessibility as Html exposing (Html)
import Api.Author as Author exposing (Author(..))
import Api.Data
import Api.Post exposing (Post)
import Components.PostList as PostList
import Effect exposing (Effect)
import Html.Attributes as Attributes
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import Store exposing (Store)
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared.store
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout model =
    Layouts.Common {}



-- INIT


type alias Model =
    ()


init : () -> ( Model, Effect Msg )
init () =
    ( ()
    , Effect.getPostsAndAuthors
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Store -> Model -> View Msg
view store model =
    let
        posts =
            Store.posts store
    in
    { title = "Home"
    , body =
        [ viewAuthors posts store.authorsList
        , viewPosts posts
        ]
    }


viewPosts : Api.Data.Data (List Post) -> Html msg
viewPosts webDataPosts =
    Html.section [ Attributes.class "grid gap-2" ]
        (Html.h2
            [ Attributes.class "px-4 text-2xl font-bold" ]
            [ Html.a [ Route.Path.href Route.Path.Posts ] [ Html.text "Posts" ] ]
            :: (webDataPosts
                    |> Api.Data.view_ PostList.view
               )
        )


viewAuthors : Api.Data.Data (List Post) -> Api.Data.Data (List (Author Author.Preview)) -> Html msg
viewAuthors dataPosts dataAuthors =
    let
        viewAuthor author =
            let
                postIds =
                    Author.postIds author

                imageCount =
                    dataPosts
                        |> Api.Data.withDefault []
                        |> List.concatMap (\post -> post.imageIds)
                        |> List.length
            in
            Html.li
                [ Attributes.class "grid grid-flow-col gap-4 items-baseline py-2 px-4 bg-white rounded-lg shadow-sm grid-cols-[auto_1fr]" ]
                [ Html.span [ Attributes.class "flex gap-1 items-baseline" ]
                    [ Html.span [ Attributes.class "text-slate-800" ] [ Html.text (Author.name author) ]
                    , Html.span
                        [ Attributes.class "flex gap-2 px-2 text-xs font-semibold rounded-md text-slate-500" ]
                        [ Html.span [] [ Html.text "✏" ], Html.span [] [ Html.text (String.fromInt (List.length postIds)) ] ]
                    , Html.span
                        [ Attributes.class "flex gap-2 px-2 text-xs font-semibold rounded-md text-slate-500" ]
                        [ Html.span [] [ Html.text "📸" ], Html.span [] [ Html.text (String.fromInt imageCount) ] ]
                    ]
                , Html.span [ Attributes.class "text-sm line-clamp-1 text-slate-500" ] [ Html.text (Author.bio author) ]
                ]
    in
    Html.section [ Attributes.class "grid gap-2" ]
        (Html.h2 [ Attributes.class "px-4 text-2xl font-bold" ] [ Html.text "Authors" ]
            :: (dataAuthors
                    |> Api.Data.view_
                        (\authors ->
                            Html.ul [ Attributes.class "dg dg-col-gap-2 dg-min-cols-2" ]
                                (authors |> List.map viewAuthor)
                        )
               )
        )



-- viewButton : String -> msg -> Html msg
-- viewButton content msg =
--     Html.button
--         [ Html.Events.onClick msg
--         , Attributes.class "py-1 px-3 text-sm font-medium rounded-md transition-colors duration-200 bg-slate-600 text-slate-100 hover:bg-slate-800 hover:text-slate-50"
--         ]
--         [ Html.text content ]
