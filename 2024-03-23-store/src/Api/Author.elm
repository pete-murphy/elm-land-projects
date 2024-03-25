module Api.Author exposing
    ( Author
    , Full
    , Preview
    , bio
    , decoder
    , exampleGetAll
    , getAll
    , getById
    , id
    , name
    , postIds
    , posts
    )

import Api.AuthorId as AuthorId exposing (AuthorId)
import Api.Post as Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type Author a
    = Author Internals a


type alias Internals =
    { id : AuthorId
    , name : String
    , bio : String
    }


type Preview
    = Preview (List PostId)


type Full
    = Full (List Post)



-- ACCESSORS


postIds : Author Preview -> List PostId
postIds (Author _ (Preview postIds_)) =
    postIds_


posts : Author Full -> List Post
posts (Author _ (Full posts_)) =
    posts_


id : Author a -> AuthorId
id (Author internals _) =
    internals.id


name : Author a -> String
name (Author internals _) =
    internals.name


bio : Author a -> String
bio (Author internals _) =
    internals.bio



-- DECODER


decoder : Decoder (a -> Author a)
decoder =
    let
        internalsDecoder =
            Decode.succeed Internals
                |> Pipeline.required "id" AuthorId.decoder
                |> Pipeline.required "name" Decode.string
                |> Pipeline.required "bio" Decode.string
    in
    Decode.succeed Author
        |> Pipeline.custom internalsDecoder



-- HTTP


getAll : (Result Http.Error (List (Author Preview)) -> msg) -> Cmd msg
getAll toMsg =
    Http.get
        { url = "/api/authors"
        , expect =
            Http.expectJson toMsg
                (Decode.list
                    (decoder
                        |> Pipeline.required "postIds"
                            (Decode.list PostId.decoder |> Decode.map Preview)
                    )
                )
        }



-- exampleGetAll : GetAll


exampleGetAll =
    """
[
    {
        "id": "1",
        "name": "John Doe",
        "bio": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "postIds": ["1", "2"]
    },
    {
        "id": "2",
        "name": "Jane Doe",
        "bio": "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "postIds": ["3", "4"]
    }
]
"""
        |> Decode.decodeString (Decode.list (decoder |> Pipeline.required "postIds" (Decode.list PostId.decoder)))
        |> Result.withDefault []


getById : AuthorId -> (Result Http.Error (Author Full) -> msg) -> Cmd msg
getById authorId toMsg =
    Http.get
        { url = "/api/authors" ++ AuthorId.toString authorId
        , expect =
            Http.expectJson toMsg
                (decoder |> Pipeline.required "posts" (Decode.list Post.decoder |> Decode.map Full))
        }
