module OpaqueDict exposing
    ( Methods
    , OpaqueDict
    , make
    )

import Dict


type OpaqueDict k comparable a
    = OpaqueDict (Dict.Dict comparable a)


type alias Methods k comparable a b =
    { empty : OpaqueDict k comparable a
    , insert : k -> a -> OpaqueDict k comparable a -> OpaqueDict k comparable a
    , map : (k -> a -> b) -> OpaqueDict k comparable a -> OpaqueDict k comparable b
    , get : k -> OpaqueDict k comparable a -> Maybe a
    , foldl : (k -> a -> b -> b) -> b -> OpaqueDict k comparable a -> b
    , remove : k -> OpaqueDict k comparable a -> OpaqueDict k comparable a
    , update : k -> (Maybe a -> Maybe a) -> OpaqueDict k comparable a -> OpaqueDict k comparable a
    , fromList : List ( k, a ) -> OpaqueDict k comparable a
    }


make :
    (k -> comparable)
    -> (comparable -> k)
    -> Methods k comparable a b
make to from =
    { empty = OpaqueDict Dict.empty
    , insert = \key value (OpaqueDict dict) -> OpaqueDict (Dict.insert (to key) value dict)
    , map = \f (OpaqueDict dict) -> OpaqueDict (Dict.map (f << from) dict)
    , foldl = \f b (OpaqueDict dict) -> Dict.foldl (f << from) b dict
    , get = \key (OpaqueDict dict) -> Dict.get (to key) dict
    , remove = \key (OpaqueDict dict) -> OpaqueDict (Dict.remove (to key) dict)
    , update = \key f (OpaqueDict dict) -> OpaqueDict (Dict.update (to key) f dict)
    , fromList = \list -> OpaqueDict (Dict.fromList (List.map (\( key, value ) -> ( to key, value )) list))
    }
