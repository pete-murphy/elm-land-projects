module Pages.Home_ exposing (Model, Msg, page, view, viewAuthors, viewPosts)

import Accessibility as Html exposing (Html)
import Api.Author as Author exposing (Author(..))
import Api.AuthorId as AuthorId
import Api.Data
import Api.Post exposing (Post)
import Api.PostId as PostId
import Components.PostList as PostList
import CustomElements
import Effect exposing (Effect)
import Html.Attributes as Attributes
import Html.Events
import Http
import Http.Extra
import Layouts
import Maybe.Extra
import Page exposing (Page)
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Extra
import Result.Extra
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
            store.postsList
                |> Api.Data.map
                    (List.map
                        (\postId ->
                            store.postsById
                                |> Api.Data.getWith PostId.dict.get postId
                        )
                    )
    in
    { title = "Home"
    , body =
        [ viewAuthors posts store.authorsList
        , viewPosts posts
        ]
    }


viewPosts : Api.Data.Data (List (Api.Data.Data Post)) -> Html msg
viewPosts webDataPosts =
    Html.section [ Attributes.class "grid gap-2" ]
        [ Html.h2
            [ Attributes.class "px-4 text-2xl font-bold" ]
            [ Html.a [ Route.Path.href Route.Path.Posts ] [ Html.text "Posts" ] ]
        , webDataPosts
            |> Api.Data.view_ PostList.view
        ]


viewAuthors : Api.Data.Data (List (Api.Data.Data Post)) -> Api.Data.Data (List (Author Author.Preview)) -> Html msg
viewAuthors webDataPosts webDataAuthors =
    let
        viewAuthor author =
            let
                postIds =
                    Author.postIds author

                imageCount =
                    webDataPosts
                        |> Api.Data.withDefault []
                        |> List.filterMap Api.Data.toMaybe
                        |> List.filter (\post -> List.member post.id postIds)
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
        [ Html.h2 [ Attributes.class "px-4 text-2xl font-bold" ] [ Html.text "Authors" ]
        , webDataAuthors
            |> Api.Data.view_
                (\authors ->
                    Html.ul [ Attributes.class "dg dg-col-gap-2 dg-min-cols-2" ]
                        (authors |> List.map viewAuthor)
                )
        ]



-- viewButton : String -> msg -> Html msg
-- viewButton content msg =
--     Html.button
--         [ Html.Events.onClick msg
--         , Attributes.class "py-1 px-3 text-sm font-medium rounded-md transition-colors duration-200 bg-slate-600 text-slate-100 hover:bg-slate-800 hover:text-slate-50"
--         ]
--         [ Html.text content ]
