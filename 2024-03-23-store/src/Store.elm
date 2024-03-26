module Store exposing (..)

import Api.Author as Author exposing (Author)
import Api.AuthorId as AuthorId
import Api.Data
import Api.Image exposing (Image)
import Api.ImageId as ImageId
import Api.Post exposing (Post)
import Api.PostId as PostId exposing (PostId)


type alias Store =
    -- Should each module export its own Store?
    { postsList : Api.Data.Data (List PostId)
    , postsById : PostId.Dict (Api.Data.Data Post)
    , authorsList : Api.Data.Data (List (Author Author.Preview))
    , authorsById : AuthorId.Dict (Api.Data.Data (Author Author.Full))
    , imagesById : ImageId.Dict (Api.Data.Data Image)
    }


init : Store
init =
    { postsList = Api.Data.notAsked
    , postsById = PostId.dict.empty
    , authorsList = Api.Data.notAsked
    , authorsById = AuthorId.dict.empty
    , imagesById = ImageId.dict.empty
    }


posts : Store -> Api.Data.Data (List Post)
posts store =
    store.postsList
        |> Api.Data.concatMap
            (Api.Data.traverseList
                (\postId ->
                    store.postsById
                        |> Api.Data.getWith PostId.dict.get postId
                )
            )
