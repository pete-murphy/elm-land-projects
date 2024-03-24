module CustomElements exposing
    ( collapsibleHeader
    , localeFloat
    , localeInt
    , relativeTime
    )

{-| Elm bindings to custom elements used in the app.
-}

import Date exposing (Date)
import Html exposing (Attribute, Html)
import Html.Attributes as Attributes
import Iso8601
import Time


{-| A header element that hides on scroll down (of document) and reappears on
scroll up.
-}
collapsibleHeader : List (Attribute Never) -> List (Html msg) -> Html msg
collapsibleHeader attrs =
    Html.node "collapsible-header" (nonInteractive attrs)


localeFloat : Float -> { fractionDigits : Int } -> Html msg
localeFloat n options =
    Html.node "locale-number"
        [ Attributes.attribute "value" (String.fromFloat n)

        -- , Attributes.attribute "locale" locale
        , Attributes.attribute "fraction-digits" (String.fromInt options.fractionDigits)
        ]
        []


localeInt : Int -> Html msg
localeInt n =
    -- let
    --     locale =
    --         I18n.currentLanguage i18n |> I18n.languageToString
    -- in
    Html.node "locale-number"
        [ Attributes.attribute "value" (String.fromInt n)

        -- , Attributes.attribute "locale" locale
        ]
        []


relativeTime : Time.Posix -> Html msg
relativeTime date =
    -- let
    --     locale =
    --         I18n.currentLanguage i18n |> I18n.languageToString
    -- in
    Html.node "relative-time"
        [ Attributes.attribute "datetime" (Iso8601.fromTime date)

        -- , Attributes.attribute "lang" locale
        -- , Attributes.attribute "prefix" ""
        , Attributes.attribute "precision" "second"
        ]
        []



-- INTERNAL


nonInteractive : List (Attribute Never) -> List (Attribute msg)
nonInteractive =
    List.map (Attributes.map never)
