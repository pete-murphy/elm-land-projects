module Api.AuthorId exposing
    ( AuthorId
    , decoder
    , toString
    )

import Json.Decode as Decode


type AuthorId
    = AuthorId String


decoder : Decode.Decoder AuthorId
decoder =
    Decode.map AuthorId Decode.string


toString : AuthorId -> String
toString (AuthorId id) =
    id
