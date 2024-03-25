module Api.AuthorId exposing
    ( AuthorId
    , Dict
    , decoder
    , dict
    , toString
    )

import Json.Decode as Decode
import OpaqueDict exposing (OpaqueDict)


type AuthorId
    = AuthorId String


decoder : Decode.Decoder AuthorId
decoder =
    Decode.map AuthorId Decode.string


toString : AuthorId -> String
toString (AuthorId id) =
    id


type alias Dict a =
    OpaqueDict AuthorId String a


dict =
    OpaqueDict.make toString AuthorId
