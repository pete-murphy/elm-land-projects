module Pages.Posts exposing (Model, Msg, page)

import Api.Data
import Components.PostList as PostList
import Effect exposing (Effect)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Store
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared
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
    , Effect.getPosts
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Posts"
    , body =
        Api.Data.view_ PostList.view (Store.posts shared.store)
    }
