module Api.PostId exposing
    ( PostId
    , decoder
    , toString
    )

import Json.Decode as Decode


type PostId
    = PostId String


decoder : Decode.Decoder PostId
decoder =
    Decode.map PostId Decode.string


toString : PostId -> String
toString (PostId id) =
    id
