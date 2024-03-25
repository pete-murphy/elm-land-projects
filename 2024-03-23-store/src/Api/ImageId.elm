module Api.ImageId exposing
    ( Dict
    , ImageId
    , decoder
    , dict
    , get
    , toString
    )

import Api.Data as Data
import Json.Decode as Decode exposing (Decoder)
import OpaqueDict exposing (OpaqueDict)


type ImageId
    = ImageId String


toString : ImageId -> String
toString (ImageId id) =
    id



-- DECODER


decoder : Decoder ImageId
decoder =
    Decode.map ImageId Decode.string



-- DICT


type alias Dict a =
    OpaqueDict ImageId String a


dict =
    OpaqueDict.make toString ImageId


get : ImageId -> Dict (Data.Data a) -> Data.Data a
get =
    Data.getWith dict.get
