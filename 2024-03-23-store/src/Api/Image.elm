module Api.Image exposing
    ( Image
    , ImageId
    , decoder
    , decoderImageId
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type ImageId
    = ImageId String


type alias Image =
    { id : ImageId
    , url : String
    }



-- DECODER


decoder : Decoder Image
decoder =
    Decode.succeed Image
        |> Pipeline.required "id" decoderImageId
        |> Pipeline.required "url" Decode.string


decoderImageId : Decoder ImageId
decoderImageId =
    Decode.map ImageId Decode.string
