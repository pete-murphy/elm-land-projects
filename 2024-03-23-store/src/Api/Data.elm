module Api.Data exposing
    ( Data
    , Value(..)
    , fail
    , fromResult
    , get
    , getWith
    , isLoading
    , loading
    , map
    , notAsked
    , succeed
    , toLoading
    , toMaybe
    , unwrap
    , value
    , view_
    , withDefault
    )

import Accessibility as Html exposing (Html)
import Dict
import Http
import Http.Extra
import Maybe.Extra


type Data a
    = Data (Internals a)


type alias Internals a =
    { value : Value a
    , isLoading : Bool
    }


type Value a
    = Empty
    | HttpError Http.Error
    | Success a



-- CONSTRUCTORS


notAsked : Data a
notAsked =
    Data { value = Empty, isLoading = False }


loading : Data a
loading =
    Data { value = Empty, isLoading = True }


succeed : a -> Data a
succeed a =
    Data { value = Success a, isLoading = False }


fail : Http.Error -> Data a
fail error =
    Data { value = HttpError error, isLoading = False }


fromResult : Result Http.Error a -> Data a
fromResult result =
    case result of
        Ok a ->
            succeed a

        Err error ->
            fail error



-- COMBINATORS


mapLoading : (Bool -> Bool) -> Data a -> Data a
mapLoading f (Data internals) =
    Data { internals | isLoading = f internals.isLoading }


toLoading : Data a -> Data a
toLoading =
    mapLoading (\_ -> True)


map : (a -> b) -> Data a -> Data b
map f (Data internals) =
    Data
        (case internals.value of
            Empty ->
                { value = Empty, isLoading = internals.isLoading }

            HttpError error ->
                { value = HttpError error, isLoading = internals.isLoading }

            Success a ->
                { value = Success (f a), isLoading = internals.isLoading }
        )



-- DESTRUCTORS


withDefault : a -> Data a -> a
withDefault default (Data internals) =
    case internals.value of
        Success a ->
            a

        _ ->
            default


toMaybe : Data a -> Maybe a
toMaybe (Data internals) =
    case internals.value of
        Success a ->
            Just a

        _ ->
            Nothing


value : Data a -> Value a
value (Data internals) =
    internals.value


isLoading : Data a -> Bool
isLoading (Data internals) =
    internals.isLoading


unwrap : Data a -> Internals a
unwrap (Data data) =
    data



-- DICT


getWith : (k -> dict -> Maybe (Data a)) -> k -> dict -> Data a
getWith getter key dict =
    getter key dict |> Maybe.withDefault notAsked


get : comparable -> Dict.Dict comparable (Data a) -> Data a
get =
    getWith Dict.get



-- HTML


view_ : (a -> Html msg) -> Data a -> Html msg
view_ toHtml (Data data) =
    case ( data.value, data.isLoading ) of
        ( Success a, _ ) ->
            toHtml a

        ( _, True ) ->
            Html.text "Loading"

        ( Empty, _ ) ->
            Html.text "Not Asked"

        ( HttpError error, _ ) ->
            case Http.Extra.errorToMessage error of
                { title, details } ->
                    Html.div []
                        (Maybe.Extra.values
                            [ Just (Html.h2 [] [ Html.text title ])
                            , details |> Maybe.map (\m -> Html.pre [] [ Html.text m ])
                            ]
                        )
