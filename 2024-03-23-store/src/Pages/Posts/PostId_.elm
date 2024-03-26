module Pages.Posts.PostId_ exposing (Model, Msg, page)

import Accessibility as Html exposing (Html)
import Api.Data
import Api.Image exposing (Image)
import Api.ImageId as ImageId exposing (ImageId)
import Api.Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
import CustomElements
import Effect exposing (Effect)
import Html.Attributes as Attributes
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route { postId : String } -> Page Model Msg
page shared route =
    let
        postId =
            PostId.fromRoute route

        imageIds =
            shared.store.postsById
                |> Api.Data.getWith PostId.dict.get postId
                |> Api.Data.map .imageIds
                |> Api.Data.withDefault []
    in
    Page.new
        { init = init postId imageIds
        , update = update
        , subscriptions = subscriptions
        , view = view shared postId
        }
        |> Page.withLayout toLayout


toLayout : Model -> Layouts.Layout Msg
toLayout model =
    Layouts.Common {}



-- INIT


type alias Model =
    ()


init : PostId -> List ImageId -> () -> ( Model, Effect Msg )
init postId imageIds () =
    ( ()
    , Effect.batch
        [ Effect.getPostByIdAndImages postId
        , Effect.getImagesById imageIds
        ]
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


view : Shared.Model -> PostId -> Model -> View Msg
view shared postId model =
    let
        post =
            shared.store.postsById
                |> Api.Data.getWith PostId.dict.get postId

        title =
            case post |> Api.Data.value of
                Api.Data.Empty ->
                    "Loading..."

                Api.Data.HttpError _ ->
                    "Something went wrong!"

                Api.Data.Success post_ ->
                    post_.title

        images =
            post
                |> Api.Data.map .imageIds
                |> Api.Data.withDefault []
                |> Api.Data.traverseList
                    (\imageId -> shared.store.imagesById |> Api.Data.getWith ImageId.dict.get imageId)
    in
    { title = title
    , body =
        Api.Data.view_ (viewPost images) post
    }


viewPost : Api.Data.Data (List Image) -> Post -> Html Msg
viewPost dataImages post =
    Html.div []
        ([ Html.div [ Attributes.class "px-4 flex gap-4 items-baseline" ]
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
         ]
            ++ (dataImages
                    |> Api.Data.view_
                        (\images ->
                            Html.div []
                                (images
                                    |> List.map
                                        (\image ->
                                            Html.img "" [ Attributes.src image.url, Attributes.class "w-full" ]
                                        )
                                )
                        )
               )
        )
