module Effect exposing
    ( Effect
    , none, batch
    , sendCmd, sendMsg
    , pushRoute, replaceRoute
    , pushRoutePath, replaceRoutePath
    , loadExternalUrl, back
    , map, toCmd
    , getImagesById, getPostByIdAndImages, getPosts, getPostsAndAuthors, runActions
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

import Api.Author as Author
import Api.AuthorId as AuthorId
import Api.Data
import Api.Image as Image
import Api.ImageId as ImageId exposing (ImageId)
import Api.Post as Post
import Api.PostId as PostId exposing (PostId)
import Browser.Navigation
import Dict exposing (Dict)
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


getPostsAndAuthors : Effect msg
getPostsAndAuthors =
    pushActions [ Store.Action.GetPosts, Store.Action.GetAuthors ]


getPostByIdAndImages : PostId -> Effect msg
getPostByIdAndImages postId =
    pushActions [ Store.Action.GetPostById postId ]


getPosts : Effect msg
getPosts =
    pushActions [ Store.Action.GetPosts ]


getImagesById : List ImageId -> Effect msg
getImagesById imageIds =
    pushActions (List.map Store.Action.GetImageById imageIds)



-- ACTION INTERNALS


pushActions : List Store.Action.Action -> Effect msg
pushActions actions =
    Store.Msg.GotActions actions
        |> Shared.Msg.GotActionMsg
        |> SendSharedMsg


runActions : Store -> List Store.Action.Action -> ( Store, Effect Store.Msg.Msg )
runActions store =
    List.foldl
        (\action ( previousStore, previousEffects ) ->
            let
                ( nextModel, nextEffect ) =
                    runAction previousStore action
            in
            ( nextModel, nextEffect :: previousEffects )
        )
        ( store, [] )
        >> Tuple.mapSecond batch


runAction : Store -> Store.Action.Action -> ( Store, Effect Store.Msg.Msg )
runAction store action =
    let
        onSuccess =
            Result.Extra.unpack (Store.Msg.GotErrorFor action)
    in
    case action of
        Store.Action.GetPostById postId ->
            -- Stale while revalidate
            ( { store
                | postsById =
                    store.postsById
                        |> PostId.dict.update postId
                            (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
              }
            , Post.getById postId (onSuccess Store.Msg.GotPost)
                |> SendCmd
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
                    , Image.getById imageId (onSuccess Store.Msg.GotImage)
                        |> SendCmd
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
            , Author.getAll (onSuccess Store.Msg.GotAuthors)
                |> SendCmd
            )

        Store.Action.GetAuthorById authorId ->
            -- Stale while revalidate
            ( { store
                | authorsById =
                    store.authorsById
                        |> AuthorId.dict.update authorId
                            (Maybe.withDefault Api.Data.notAsked >> Api.Data.toLoading >> Just)
              }
            , Author.getById authorId (onSuccess Store.Msg.GotAuthor)
                |> SendCmd
            )

        Store.Action.GetPosts ->
            -- Stale while revalidate
            ( { store
                | postsList =
                    store.postsList |> Api.Data.toLoading
              }
            , Post.getAll (onSuccess Store.Msg.GotPosts)
                |> SendCmd
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
