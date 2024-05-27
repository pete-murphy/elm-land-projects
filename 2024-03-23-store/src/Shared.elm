module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Api.Author as Author
import Api.AuthorId as AuthorId
import Api.Data
import Api.ImageId as ImageId
import Api.PostId as PostId
import Effect exposing (Effect)
import Json.Decode
import Route exposing (Route)
import Shared.Model
import Shared.Msg
import Store
import Store.Action
import Store.Msg



-- FLAGS


type alias Flags =
    {}


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.succeed {}



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    ( { store = Store.init }
    , Effect.none
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        Shared.Msg.NoOp ->
            ( model
            , Effect.none
            )

        Shared.Msg.GotActionMsg actionMsg ->
            let
                ( nextStore_, effect ) =
                    let
                        store =
                            model.store
                    in
                    case actionMsg of
                        Store.Msg.GotActions actions ->
                            Effect.runActions store actions

                        Store.Msg.GotErrorFor action error ->
                            -- TODO: Save error
                            ( store, Effect.none )

                        Store.Msg.GotAuthor author ->
                            let
                                nextStore =
                                    { store | authorsById = AuthorId.dict.insert (Author.id author) (Api.Data.succeed author) store.authorsById }

                                nextActions =
                                    author
                                        |> Author.posts
                                        |> List.concatMap
                                            (.imageIds >> List.map Store.Action.GetImageById)
                            in
                            Effect.runActions nextStore nextActions

                        Store.Msg.GotAuthors authors ->
                            let
                                nextStore =
                                    { store | authorsList = Api.Data.succeed authors }
                            in
                            ( nextStore, Effect.none )

                        Store.Msg.GotPost post ->
                            let
                                nextStore =
                                    { store | postsById = PostId.dict.insert post.id (Api.Data.succeed post) store.postsById }

                                nextActions =
                                    post.imageIds
                                        |> List.map Store.Action.GetImageById
                            in
                            Effect.runActions nextStore nextActions

                        Store.Msg.GotPosts posts ->
                            let
                                nextStore =
                                    { store
                                        | postsList = Api.Data.succeed (posts |> List.map .id)
                                        , postsById = posts |> List.map (\post -> ( post.id, Api.Data.succeed post )) |> PostId.dict.fromList
                                    }
                            in
                            ( nextStore, Effect.none )

                        Store.Msg.GotImage image ->
                            let
                                nextStore =
                                    { store | imagesById = ImageId.dict.insert image.id (Api.Data.succeed image) store.imagesById }
                            in
                            ( nextStore, Effect.none )

                        Store.Msg.NoOp ->
                            ( store, Effect.none )
            in
            ( { model | store = nextStore_ }
            , effect
                |> Effect.map Shared.Msg.GotActionMsg
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.none
