module Api.Author exposing
    ( Author(..)
    , GetAll
    , GetById
    , decoder
    , exampleGetAll
    , getAll
    , getById
    )

import Api.AuthorId as AuthorId exposing (AuthorId)
import Api.Post as Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline as Pipeline


type Author a
    = Author Internals a


type alias Internals =
    { id : AuthorId
    , name : String
    , bio : String
    }


type alias GetAll =
    List (Author (List PostId))


type alias GetById =
    Author (List Post)



-- DECODER


decoder : Decoder Internals
decoder =
    Decode.succeed Internals
        |> Pipeline.required "id" AuthorId.decoder
        |> Pipeline.required "name" Decode.string
        |> Pipeline.required "bio" Decode.string


decoderGetAll : Decoder GetAll
decoderGetAll =
    Decode.list
        (Decode.succeed Author
            |> Json.Decode.Extra.andMap decoder
            |> Pipeline.required "postIds" (Decode.list PostId.decoder)
        )


decoderGetById : Decoder GetById
decoderGetById =
    Decode.succeed Author
        |> Json.Decode.Extra.andMap decoder
        |> Pipeline.required "posts" (Decode.list Post.decoder)



-- HTTP


getAll : (Result Http.Error GetAll -> msg) -> Cmd msg
getAll toMsg =
    Http.get
        { url = "/api/authors"
        , expect = Http.expectJson toMsg decoderGetAll
        }


exampleGetAll : GetAll
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
        |> Decode.decodeString decoderGetAll
        |> Result.withDefault []


getById : (Result Http.Error (Author (List Post)) -> msg) -> Cmd msg
getById toMsg =
    Http.get
        { url = "/api/authors"
        , expect = Http.expectJson toMsg decoderGetById
        }
