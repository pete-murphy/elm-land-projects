module Effect exposing
    ( Effect
    , none, batch
    , sendCmd, sendMsg
    , pushRoute, replaceRoute
    , pushRoutePath, replaceRoutePath
    , loadExternalUrl, back
    , map, toCmd
    , getAuthorById, getAuthors, getImageById, getPostById, getPosts, getPostsAndAuthors, runActions
    )

{-|

@docs Effect

@docs none, batch
@docs sendCmd, sendMsg

@docs pushRoute, replaceRoute
@docs pushRoutePath, replaceRoutePath
@docs loadExternalUrl, back

@docs map, toCmd

-}

import Api.Author as Author exposing (Author)
import Api.AuthorId as AuthorId exposing (AuthorId)
import Api.Data
import Api.Image as Image exposing (Image)
import Api.ImageId as ImageId exposing (ImageId)
import Api.Post as Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
import Browser.Navigation
import Dict exposing (Dict)
import Http
import Result.Extra
import Route
import Route.Path
import Shared.Model
import Shared.Msg
import Store exposing (Store)
import Store.Action
import Store.Msg
import Task
import Url exposing (Url)


type Effect msg
    = -- BASICS
      None
    | Batch (List (Effect msg))
    | SendCmd (Cmd msg)
      -- ROUTING
    | PushUrl String
    | ReplaceUrl String
    | LoadExternalUrl String
    | Back
      -- SHARED
    | SendSharedMsg Shared.Msg.Msg



-- BASICS


{-| Don't send any
-}
none : Effect msg
none =
    None


{-| Send multiple effects at once.
-}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| Send a normal `Cmd msg` as an effect, something like `Http.get` or `Random.generate`.
-}
sendCmd : Cmd msg -> Effect msg
sendCmd =
    SendCmd


{-| Send a message as an Useful when emitting events from UI components.
-}
sendMsg : msg -> Effect msg
sendMsg msg =
    Task.succeed msg
        |> Task.perform identity
        |> SendCmd



-- HTTP


getPosts : (Result Http.Error (List Post) -> msg) -> Effect msg
getPosts toMsg =
    Post.getAll toMsg
        |> SendCmd


getPostById : PostId -> (Result Http.Error Post -> msg) -> Effect msg
getPostById postId toMsg =
    Post.getById postId toMsg
        |> SendCmd


getAuthors : (Result Http.Error (List (Author Author.Preview)) -> msg) -> Effect msg
getAuthors toMsg =
    Author.getAll toMsg |> SendCmd


getAuthorById : AuthorId -> (Result Http.Error (Author Author.Full) -> msg) -> Effect msg
getAuthorById authorId toMsg =
    Author.getById authorId toMsg |> SendCmd


getImageById : ImageId -> (Result Http.Error Image -> msg) -> Effect msg
getImageById imageId toMsg =
    Image.getById (Debug.log "imageId" imageId) toMsg
        |> SendCmd



-- RUN ACTIONS (TODO: Remove the above functions)


getPostsAndAuthors : Effect msg
getPostsAndAuthors =
    Store.Msg.GotActions [ Store.Action.GetPosts, Store.Action.GetAuthors ]
        |> Shared.Msg.GotActionMsg
        |> SendSharedMsg


getPostByIdAndImages : PostId -> Effect msg
getPostByIdAndImages postId =
    Store.Msg.GotActions [ Store.Action.GetPostById postId (.imageIds >> List.map Store.Action.GetImageById) ]
        |> Shared.Msg.GotActionMsg
        |> SendSharedMsg



-- ROUTING


{-| Set the new route, and make the back button go back to the current route.
-}
pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


{-| Same as `pushRoute`, but without `query` or `hash` support
-}
pushRoutePath : Route.Path.Path -> Effect msg
pushRoutePath path =
    PushUrl (Route.Path.toString path)


{-| Set the new route, but replace the previous one, so clicking the back
button **won't** go back to the previous route.
-}
replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)


{-| Same as `replaceRoute`, but without `query` or `hash` support
-}
replaceRoutePath : Route.Path.Path -> Effect msg
replaceRoutePath path =
    ReplaceUrl (Route.Path.toString path)


{-| Redirect users to a new URL, somewhere external your web application.
-}
loadExternalUrl : String -> Effect msg
loadExternalUrl =
    LoadExternalUrl


{-| Navigate back one page
-}
back : Effect msg
back =
    Back



-- ACTIONS


runActions : Store -> List Store.Action.Action -> ( Store, Effect Store.Msg.Msg )
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
        >> Tuple.mapSecond batch


runAction action store =
    let
        onSuccess =
            Result.Extra.unpack (Store.Msg.GotErrorFor action)
    in
    case action of
        Store.Action.GetPostById postId toNextActions ->
            -- Stale while revalidate
            ( { store
                | postsById =
                    store.postsById
                        |> PostId.dict.update postId
                            (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
              }
            , getPostById postId (onSuccess (\post -> Store.Msg.GotPost post (toNextActions post)))
            )

        Store.Action.GetImageById imageId ->
            -- Cache first
            let
                dataImage =
                    ImageId.get imageId store.imagesById |> Api.Data.unwrap
            in
            case ( dataImage.isLoading, dataImage.value ) of
                ( True, _ ) ->
                    ( store, none )

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
                    , getImageById imageId (onSuccess Store.Msg.GotImage)
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
                    ( store, none )

                ( False, Api.Data.Success image ) ->
                    -- ( store_, sendMsg (GotImage image) )
                    -- Should 👆 this be 👇 this?
                    ( { store
                        | imagesById =
                            store.imagesById
                                |> ImageId.dict.insert imageId (Api.Data.succeed image)
                      }
                    , none
                    )

        Store.Action.GetAuthors ->
            -- Stale while revalidate
            ( { store
                -- Not doing anything with authorsById
                | authorsList =
                    store.authorsList |> Api.Data.toLoading
              }
            , getAuthors (onSuccess Store.Msg.GotAuthors)
            )

        Store.Action.GetAuthorById authorId toNextActions ->
            -- Stale while revalidate
            ( { store
                | authorsById =
                    store.authorsById
                        |> AuthorId.dict.update authorId
                            (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
              }
            , getAuthorById authorId (onSuccess (\author -> Store.Msg.GotAuthor author (toNextActions author)))
            )

        Store.Action.GetPosts ->
            -- Stale while revalidate
            ( { store
                | postsList =
                    store.postsList |> Api.Data.toLoading
              }
            , getPosts (onSuccess Store.Msg.GotPosts)
            )



-- INTERNALS


{-| Elm Land depends on this function to connect pages and layouts
together into the overall app.
-}
map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        SendCmd cmd ->
            SendCmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        Back ->
            Back

        LoadExternalUrl url ->
            LoadExternalUrl url

        SendSharedMsg sharedMsg ->
            SendSharedMsg sharedMsg


{-| Elm Land depends on this function to perform your effects.
-}
toCmd :
    { key : Browser.Navigation.Key
    , url : Url
    , shared : Shared.Model.Model
    , fromSharedMsg : Shared.Msg.Msg -> msg
    , batch : List msg -> msg
    , toCmd : msg -> Cmd msg
    }
    -> Effect msg
    -> Cmd msg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        SendCmd cmd ->
            cmd

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        Back ->
            Browser.Navigation.back options.key 1

        LoadExternalUrl url ->
            Browser.Navigation.load url

        SendSharedMsg sharedMsg ->
            Task.succeed sharedMsg
                |> Task.perform options.fromSharedMsg
