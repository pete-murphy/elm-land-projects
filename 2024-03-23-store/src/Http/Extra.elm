module Http.Extra exposing (..)

import Http


errorToMessage : Http.Error -> { title : String, details : Maybe String }
errorToMessage httpError =
    case httpError of
        Http.BadUrl url ->
            { title = "Bad URL", details = Just url }

        Http.Timeout ->
            { title = "Timeout", details = Nothing }

        Http.NetworkError ->
            { title = "Network Error", details = Nothing }

        Http.BadStatus statusCode ->
            { title = "Bad Status", details = Just (String.fromInt statusCode) }

        Http.BadBody body ->
            { title = "Bad Body", details = Just body }
