module RemoteData.Extra exposing (viewWebData)

import Accessibility as Html exposing (Html)
import Http.Extra
import Maybe.Extra
import RemoteData exposing (RemoteData(..), WebData)


viewWebData : (a -> Html msg) -> WebData a -> Html msg
viewWebData toHtml webData =
    case webData of
        NotAsked ->
            Html.text "Not Asked"

        Loading ->
            Html.text "Loading"

        Success success ->
            toHtml success

        Failure error ->
            case Http.Extra.errorToMessage error of
                { title, details } ->
                    Html.div []
                        (Maybe.Extra.values
                            [ Just (Html.h2 [] [ Html.text title ])
                            , details |> Maybe.map (\m -> Html.pre [] [ Html.text m ])
                            ]
                        )
