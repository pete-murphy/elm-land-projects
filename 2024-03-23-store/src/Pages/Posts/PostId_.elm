module Pages.Posts.PostId_ exposing (Model, Msg, page)

import Accessibility as Html exposing (Html)
import Api.Author as Author exposing (Author(..))
import Api.Image exposing (Image, ImageId)
import Api.Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
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


page : Shared.Model -> Route { postId : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init (PostId.fromRoute route)
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
    { post : WebData Post
    , images : List Image
    }


init : PostId -> () -> ( Model, Effect Msg )
init postId () =
    let
        initialModel =
            { post = NotAsked
            , images = []
            }
    in
    initialModel
        |> runAction (FetchPost postId (\post -> post.imageIds |> List.map FetchImage))



-- UPDATE


type Action
    = FetchPost PostId (Post -> List Action)
    | FetchImage ImageId


type Msg
    = RunAction Action
    | GotPost Post (List Action)
    | GotImage Image
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
        FetchPost postId toNextActions ->
            ( { model | post = toLoading model.post }
            , Effect.fetchPostById postId
                (handleSuccessWith (\post -> GotPost post (toNextActions post)))
            )

        FetchImage imageId ->
            ( model
            , Effect.fetchImageById imageId (handleSuccessWith GotImage)
            )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        RunAction action ->
            runAction action model

        GotImage image ->
            ( { model | images = image :: model.images }
            , Effect.none
            )

        GotPost post nextActions ->
            nextActions
                |> List.foldl
                    (\action ( previousModel, previousEffects ) ->
                        let
                            ( nextModel, nextEffect ) =
                                runAction action previousModel
                        in
                        ( nextModel, nextEffect :: previousEffects )
                    )
                    ( { model | post = Success post }, [] )
                |> Tuple.mapSecond Effect.batch

        GotErrorFor (FetchPost _ _) error ->
            ( { model | post = Failure error }
            , Effect.none
            )

        GotErrorFor (FetchImage _) error ->
            let
                _ =
                    Debug.log "GotErrorFor FetchImage" error
            in
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
    let
        title =
            case model.post of
                NotAsked ->
                    "Not asked"

                Loading ->
                    "Loading..."

                Failure _ ->
                    "Something went wrong!"

                Success post ->
                    post.title
    in
    { title = title
    , body =
        case model.post of
            NotAsked ->
                []

            Loading ->
                []

            Failure _ ->
                []

            Success post ->
                viewPost post model.images
    }


viewPost : Post -> List Image -> List (Html Msg)
viewPost post images =
    [ Html.div [ Attributes.class "px-4 flex gap-4 items-baseline" ]
        [ Html.span [] [ Html.text post.authorName ]
        , Html.span [ Attributes.class "flex gap-2 text-sm text-slate-500" ]
            [ Html.span [] [ Html.text "📆" ]
            , Html.span [ Attributes.class "line-clamp-1" ] [ CustomElements.relativeTime post.createdAt ]
            ]
        ]
    , Html.div [ Attributes.class "m-auto px-4 grid gap-2 max-w-prose" ]
        (post.content
            |> String.split "\n"
            |> List.map (\line -> Html.p [] [ Html.text line ])
        )
    , Html.div []
        (images
            |> List.map
                (\image ->
                    Html.img "" [ Attributes.src image.url, Attributes.class "w-full" ]
                )
        )
    ]
