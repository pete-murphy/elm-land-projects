module Api.Image exposing
    ( Image
    , decoder
    , getById
    )

import Api.ImageId as ImageId exposing (ImageId)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type alias Image =
    { id : ImageId
    , url : String
    }



-- DECODER


decoder : Decoder Image
decoder =
    Decode.succeed Image
        |> Pipeline.required "id" ImageId.decoder
        |> Pipeline.required "url" Decode.string



-- HTTP


getById : ImageId -> (Result Http.Error Image -> msg) -> Cmd msg
getById imageId toMsg =
    Http.get
        { url = "/api/images/" ++ ImageId.toString imageId
        , expect = Http.expectJson toMsg decoder
        }
