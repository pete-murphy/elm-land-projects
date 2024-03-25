module Action exposing (..)

-- import Effect

import Api.Author as Author exposing (Author)
import Api.AuthorId as AuthorId exposing (AuthorId)
import Api.Data
import Api.Image as Image exposing (Image)
import Api.ImageId as ImageId exposing (ImageId)
import Api.Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
import Http
import RemoteData exposing (RemoteData(..))
import Result.Extra


type Action
    = GetPosts
    | GetPostById PostId (Post -> List Action)
    | GetAuthors
    | GetAuthorById AuthorId (Author Author.Full -> List Action)
    | GetImageById ImageId


type Msg
    = GotActions (List Action)
    | GotErrorFor Action Http.Error
      --
    | GotAuthor (Author Author.Full) (List Action)
    | GotAuthors (List (Author Author.Preview))
    | GotPost Post (List Action)
    | GotPosts (List Post)
    | GotImage Image
      --
      --
    | NoOp


runActions : Store -> List Action -> ( Store, Effect.Effect Msg )
runActions store =
    List.foldl
        (\action ( previousModel, previousEffects ) ->
            let
                ( nextModel, nextEffect ) =
                    runAction action previousModel
            in
            ( nextModel, nextEffect :: previousEffects )
        )
        ( store, [] )
        >> Tuple.mapSecond Effect.batch


runAction : Action -> Store -> ( Store, Effect.Effect Msg )
runAction action store =
    let
        onSuccess =
            Result.Extra.unpack (GotErrorFor action)
    in
    case action of
        GetPostById postId toNextActions ->
            -- Stale while revalidate
            ( { store
                | postsById =
                    store.postsById
                        |> PostId.dict.update postId
                            (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
              }
            , Effect.getPostById postId (onSuccess (\post -> GotPost post (toNextActions post)))
            )

        GetImageById imageId ->
            -- Cache first
            let
                dataImage =
                    ImageId.get imageId store.imagesById |> Api.Data.unwrap
            in
            case ( dataImage.isLoading, dataImage.value ) of
                ( True, _ ) ->
                    ( store, Effect.none )

                ( False, Api.Data.Empty ) ->
                    ( { store
                        | imagesById =
                            ImageId.dict.insert imageId
                                Api.Data.loading
                                -- Should 👆 this be 👇 this?
                                --
                                -- ImageId.dict.update imageId
                                --    (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
                                --
                                -- The latter is more general, but in this case we know the
                                -- cache at this ImageId is Empty
                                store.imagesById
                      }
                    , Effect.getImageById imageId (onSuccess GotImage)
                    )

                ( False, Api.Data.HttpError _ ) ->
                    -- TODO: Should we retry in error case? If so, we probably want to do the same
                    -- as the Empty case above (but with a retry counter(?)).
                    -- Or maybe, if we have a 401/403 we should try to refresh credentials
                    -- and _then_ retry the request.
                    --
                    -- This would be complicated to express, and we'd want to reuse that logic
                    -- probably in many places (so would need to abstract over the resource type).
                    --
                    -- 💭 A retry combinator might be able to address both those issues.
                    -- But what would the type be?
                    --
                    -- retry : (a -> (a, Effect b)) -> a -> (a, Effect b)
                    ( store, Effect.none )

                ( False, Api.Data.Success image ) ->
                    -- ( store_, Effect.sendMsg (GotImage image) )
                    -- Should 👆 this be 👇 this?
                    ( { store
                        | imagesById =
                            store.imagesById
                                |> ImageId.dict.insert imageId (Api.Data.succeed image)
                      }
                    , Effect.none
                    )

        GetAuthors ->
            -- Stale while revalidate
            ( { store
                -- Not doing anything with authorsById
                | authorsList =
                    store.authorsList |> Api.Data.toLoading
              }
            , Effect.getAuthors (onSuccess GotAuthors)
            )

        GetAuthorById authorId toNextActions ->
            -- Stale while revalidate
            ( { store
                | authorsById =
                    store.authorsById
                        |> AuthorId.dict.update authorId
                            (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
              }
            , Effect.getAuthorById authorId (onSuccess (\author -> GotAuthor author (toNextActions author)))
            )

        GetPosts ->
            -- Stale while revalidate
            ( { store
                | postsList =
                    store.postsList |> Api.Data.toLoading
              }
            , Effect.getPosts (onSuccess GotPosts)
            )
