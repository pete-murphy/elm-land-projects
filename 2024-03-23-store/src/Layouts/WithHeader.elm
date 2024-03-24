module Layouts.WithHeader exposing (Model, Msg, Props, layout)

import CustomElements
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes as Attributes exposing (class)
import Layout exposing (Layout)
import Route exposing (Route)
import Shared
import View exposing (View)


type alias Props =
    {}


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout props shared route =
    Layout.new
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = ReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ReplaceMe ->
            ( model
            , Effect.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model } -> View contentMsg
view { toContentMsg, model, content } =
    { title = content.title
    , body =
        [ Html.div [ Attributes.class "grid col-start-2 grid-rows-[auto_1fr]" ]
            [ CustomElements.collapsibleHeader
                [ Attributes.class "sticky top-0 p-8 bg-slate-50 shadow-lg shadow-[rgba(0,38,57,calc(var(--shadow-opacity)*0.1))]"
                ]
                [ Html.h1 [ Attributes.class "text-4xl font-black" ] [ Html.text content.title ] ]
            , Html.main_ [ Attributes.class "grid gap-8 p-4" ] content.body
            ]
        ]
    }
