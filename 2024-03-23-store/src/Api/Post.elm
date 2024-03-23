module Api.Post exposing
    ( Post
    , PostId
    , decoder
    , getAll
    , getById
    )

import Api.Author as Author exposing (AuthorId)
import Api.Image as Image exposing (ImageId)
import Http
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Time


type PostId
    = PostId String


type alias Post =
    { id : PostId
    , title : String
    , authorId : AuthorId
    , content : String
    , createdAt : Time.Posix
    , imageIds : List ImageId
    }



-- DECODER


decoder : Decoder Post
decoder =
    Decode.succeed Post
        |> Pipeline.required "id" (Decode.map PostId Decode.string)
        |> Pipeline.required "title" Decode.string
        |> Pipeline.required "authorId" Author.decoderAuthorId
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


getById : PostId -> (Result Http.Error Post -> msg) -> Cmd msg
getById (PostId id) toMsg =
    Http.get
        { url = "/api/posts/" ++ id
        , expect = Http.expectJson toMsg decoder
        }
