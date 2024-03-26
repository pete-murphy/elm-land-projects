module Api.PostId exposing
    ( Dict
    , PostId
    , decoder
    , dict
    , fromRoute
    , toString
    )

import Json.Decode as Decode
import OpaqueDict exposing (OpaqueDict)
import Route exposing (Route)


type PostId
    = PostId String


decoder : Decode.Decoder PostId
decoder =
    Decode.map PostId Decode.string


toString : PostId -> String
toString (PostId id) =
    id


fromRoute : Route { postId : String } -> PostId
fromRoute route =
    PostId route.params.postId


type alias Dict a =
    OpaqueDict PostId String a


dict : OpaqueDict.Methods PostId String a b
dict =
    OpaqueDict.make toString PostId
