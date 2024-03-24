module Pages.Home_ exposing (Model, Msg, page, view, viewAuthors, viewPosts)

import Accessibility as Html exposing (Html)
import Api.Author as Author exposing (Author(..))
import Api.Post exposing (Post)
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
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout model =
    Layouts.WithHeader {}



-- INIT


type alias Model =
    { posts : WebData (List Post)
    , authors : WebData Author.GetAll
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { posts = Loading
      , authors = Loading
      }
    , Effect.batch
        [ Effect.fetchPosts (Result.Extra.unpack (GotErrorFor FetchPosts) GotPosts)
        , Effect.fetchAuthors (Result.Extra.unpack (GotErrorFor FetchAuthors) GotAuthors)
        ]
    )



-- UPDATE


type Action
    = FetchPosts
    | FetchAuthors


type Msg
    = RunAction Action
    | GotPosts (List Post)
    | GotAuthors Author.GetAll
    | GotErrorFor Action Http.Error
    | NoOp


toLoading : WebData a -> WebData a
toLoading =
    RemoteData.unwrap Loading Success


runAction : Action -> Model -> ( Model, Effect Msg )
runAction action model =
    let
        handleSuccessWith =
            Result.Extra.unpack (GotErrorFor action)
    in
    case action of
        FetchPosts ->
            ( { model | posts = toLoading model.posts }
            , Effect.fetchPosts (handleSuccessWith GotPosts)
            )

        FetchAuthors ->
            ( { model | authors = toLoading model.authors }
            , Effect.fetchAuthors (handleSuccessWith GotAuthors)
            )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        RunAction action ->
            runAction action model

        GotPosts posts ->
            ( { model | posts = Success posts }
            , Effect.none
            )

        GotAuthors authors ->
            ( { model | authors = Success authors }
            , Effect.none
            )

        GotErrorFor FetchPosts error ->
            ( { model | posts = Failure error }
            , Effect.none
            )

        GotErrorFor FetchAuthors error ->
            ( { model | authors = Failure error }
            , Effect.none
            )

        NoOp ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Home"
    , body =
        [ viewAuthors model.posts model.authors
        , viewPosts model.posts
        ]
    }


viewPosts : WebData (List Post) -> Html msg
viewPosts webDataPosts =
    Html.section [ Attributes.class "grid gap-2" ]
        [ Html.h2
            [ Attributes.class "px-4 text-2xl font-bold" ]
            [ Html.a [ Route.Path.href Route.Path.Posts ] [ Html.text "Posts" ] ]
        , webDataPosts
            |> RemoteData.Extra.viewWebData PostList.view
        ]


viewAuthors : WebData (List Post) -> WebData Author.GetAll -> Html msg
viewAuthors webDataPosts webDataAuthors =
    let
        viewAuthor (Author author postIds) =
            let
                imageCount =
                    webDataPosts
                        |> RemoteData.withDefault []
                        |> List.filter (\post -> List.member post.id postIds)
                        |> List.concatMap (\post -> post.imageIds)
                        |> List.length
            in
            Html.li
                [ Attributes.class "grid grid-flow-col gap-4 items-baseline py-2 px-4 bg-white rounded-lg shadow-sm grid-cols-[auto_1fr]" ]
                [ Html.span [ Attributes.class "flex gap-1 items-baseline" ]
                    [ Html.span [ Attributes.class "text-slate-800" ] [ Html.text author.name ]
                    , Html.span
                        [ Attributes.class "flex gap-2 px-2 text-xs font-semibold rounded-md text-slate-500" ]
                        [ Html.span [] [ Html.text "✏" ], Html.span [] [ Html.text (String.fromInt (List.length postIds)) ] ]
                    , Html.span
                        [ Attributes.class "flex gap-2 px-2 text-xs font-semibold rounded-md text-slate-500" ]
                        [ Html.span [] [ Html.text "📸" ], Html.span [] [ Html.text (String.fromInt imageCount) ] ]
                    ]
                , Html.span [ Attributes.class "text-sm line-clamp-1 text-slate-500" ] [ Html.text author.bio ]
                ]
    in
    Html.section [ Attributes.class "grid gap-2" ]
        [ Html.h2 [ Attributes.class "px-4 text-2xl font-bold" ] [ Html.text "Authors" ]
        , webDataAuthors
            |> RemoteData.Extra.viewWebData
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
