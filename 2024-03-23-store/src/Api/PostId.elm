module Api.PostId exposing
    ( PostId
    , decoder
    , fromRoute
    , toString
    )

import Json.Decode as Decode
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
