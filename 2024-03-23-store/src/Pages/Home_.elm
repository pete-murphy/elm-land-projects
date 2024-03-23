module Pages.Home_ exposing (Model, Msg, page)

import Api.Post exposing (Post)
import Effect exposing (Effect)
import Html
import Html.Events
import Http
import Http.Extra
import Maybe.Extra
import Page exposing (Page)
import RemoteData exposing (RemoteData(..), WebData)
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



-- INIT


type alias Model =
    { posts : WebData (List Post)
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { posts = NotAsked }
    , Effect.none
    )



-- UPDATE


type Msg
    = FetchPosts
    | GotPosts (List Post)
    | GotErrorFor Msg Http.Error
    | NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        FetchPosts ->
            ( { model | posts = Loading }
            , Effect.fetchPosts (Result.Extra.unpack (GotErrorFor FetchPosts) GotPosts)
            )

        GotPosts posts ->
            ( { model | posts = Success posts }
            , Effect.none
            )

        GotErrorFor FetchPosts error ->
            ( { model | posts = Failure error }
            , Effect.none
            )

        GotErrorFor _ _ ->
            ( model
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
    { title = "Pages.Home_"
    , body =
        [ Html.h1 [] [ Html.text "Home" ]
        , Html.button [ Html.Events.onClick FetchPosts ] [ Html.text "Fetch Posts" ]
        , case model.posts of
            NotAsked ->
                Html.text "Not Asked"

            Loading ->
                Html.text "Loading"

            Success posts ->
                Html.ul [] (List.map (\post -> Html.li [] [ Html.text post.title ]) posts)

            Failure error ->
                case Http.Extra.errorToMessage error of
                    { title, details } ->
                        Html.div []
                            (Maybe.Extra.values
                                [ Just (Html.h2 [] [ Html.text title ])
                                , details |> Maybe.map (\m -> Html.pre [] [ Html.text m ])
                                ]
                            )
        ]
    }
