module Api.Post exposing
    ( Post
    , decoder
    , exampleGetAll
    , getAll
    , getById
    )

import Api.AuthorId as AuthorId exposing (AuthorId)
import Api.Image as Image exposing (ImageId)
import Api.PostId as PostId exposing (PostId)
import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Time


type alias Post =
    { id : PostId
    , title : String
    , authorId : AuthorId
    , authorName : String
    , content : String
    , createdAt : Time.Posix
    , imageIds : List ImageId
    }



-- DECODER


decoder : Decoder Post
decoder =
    Decode.succeed Post
        |> Pipeline.required "id" PostId.decoder
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "authorId" AuthorId.decoder
        |> Pipeline.required "authorName" Decode.string
        |> Pipeline.required "content" Decode.string
        |> Pipeline.required "createdAt" Iso8601.decoder
        |> Pipeline.required "imageIds" (Decode.list Image.decoderImageId)



-- HTTP


getAll : (Result Http.Error (List Post) -> msg) -> Cmd msg
getAll toMsg =
    Http.get
        { url = "/api/posts"
        , expect = Http.expectJson toMsg (Decode.list decoder)
        }


exampleGetAll : List Post
exampleGetAll =
    """
[
    {
        "id": "1",
        "title": "First post",
        "authorId": "1",
        "authorName": "John Doe",
        "content": "This is the first post",
        "createdAt": "2020-01-01T00:00:00Z",
        "imageIds": ["1", "2"]
    },
    {
        "id": "2",
        "title": "Second post and its a long one asdf",
        "authorId": "2",
        "authorName": "Jane Doe",
        "content": "This is the second post",
        "createdAt": "2024-03-02T00:00:00Z",
        "imageIds": ["3"]
    }
]   
"""
        |> Decode.decodeString (Decode.list decoder)
        |> Result.withDefault []


getById : PostId -> (Result Http.Error Post -> msg) -> Cmd msg
getById postId toMsg =
    Http.get
        { url = "/api/posts/" ++ PostId.toString postId
        , expect = Http.expectJson toMsg decoder
        }
