module Pages.Posts exposing (Model, Msg, page)

import Api.Post exposing (Post)
import Components.PostList as PostList
import Effect exposing (Effect)
import Html
import Http
import Layouts
import Page exposing (Page)
import RemoteData exposing (RemoteData(..), WebData)
import RemoteData.Extra
import Result.Extra
import Route exposing (Route)
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
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { posts = Loading }
    , Effect.fetchPosts (Result.Extra.unpack (GotErrorFor FetchPosts) GotPosts)
    )



-- UPDATE


type Action
    = FetchPosts


type Msg
    = RunAction Action
    | GotPosts (List Post)
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


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        RunAction action ->
            runAction action model

        GotPosts posts ->
            ( { model | posts = Success posts }
            , Effect.none
            )

        GotErrorFor FetchPosts error ->
            ( { model | posts = Failure error }
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
    { title = "Posts"
    , body =
        [ model.posts
            |> RemoteData.Extra.viewWebData
                PostList.view
        ]
    }
