module Api.Author exposing
    ( Author
    , AuthorId
    , decoder
    , decoderAuthorId
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline


type AuthorId
    = AuthorId String


type alias Author =
    { id : AuthorId
    , name : String
    }



-- DECODER


decoder : Decoder Author
decoder =
    Decode.succeed Author
        |> Pipeline.required "id" decoderAuthorId
        |> Pipeline.required "name" Decode.string


decoderAuthorId : Decoder AuthorId
decoderAuthorId =
    Decode.map AuthorId Decode.string
