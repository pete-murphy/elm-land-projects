module Pages.Example.Step_ exposing (Model, Msg, page)

import Dict exposing (Dict)
import Effect exposing (Effect)
import Form
import Html
import Html.Attributes
import Html.Events
import Maybe.Extra
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route { step : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init (stepFromRoute route)
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type Step
    = Start
    | Middle
    | End


type alias Model =
    { step : Step
    , form : Dict String String
    }


stepFromRoute : Route { step : String } -> Maybe Step
stepFromRoute route =
    case route.params.step of
        "start" ->
            Just Start

        "middle" ->
            Just Middle

        "end" ->
            Just End

        _ ->
            Nothing


stepToString : Step -> String
stepToString step =
    case step of
        Start ->
            "start"

        Middle ->
            "middle"

        End ->
            "end"


init : Maybe Step -> () -> ( Model, Effect Msg )
init maybeStep () =
    case maybeStep of
        Just step ->
            ( { step = step
              , form = Dict.empty
              }
            , Effect.none
            )

        Nothing ->
            ( { step = Start
              , form = Dict.empty
              }
            , Effect.replaceRoutePath Route.Path.Home_
            )



-- UPDATE


type Msg
    = UserBlurredInput String String
    | UserClickedSubmit
    | NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )

        UserBlurredInput key value ->
            ( { model | form = Dict.insert key value model.form }
            , Effect.none
            )

        UserClickedSubmit ->
            let
                nextStep =
                    case model.step of
                        Start ->
                            Middle

                        Middle ->
                            End

                        End ->
                            End
            in
            ( { model | step = nextStep }
            , Effect.pushRoutePath (Route.Path.Example_Step_ { step = stepToString nextStep })
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title =
        case model.step of
            Start ->
                "Start"

            Middle ->
                "Middle"

            End ->
                "End"
    , body =
        (case model.step of
            Start ->
                [ Html.h1 [] [ Html.text "Start" ]
                , Html.form []
                    [ Html.input
                        [ Html.Attributes.placeholder "Name"
                        , Html.Events.on "blur" Html.Events.targetValue
                            |> Html.Attributes.map (UserBlurredInput "name")
                        ]
                        []
                    , Html.button [ Html.Events.onClick UserClickedSubmit ] [ Html.text "Next" ]
                    ]
                ]

            Middle ->
                [ Html.h1 [] [ Html.text "Middle" ]
                , Html.form []
                    [ Html.input
                        [ Html.Attributes.placeholder "Age"
                        , Html.Events.on "blur" Html.Events.targetValue
                            |> Html.Attributes.map (UserBlurredInput "age")
                        ]
                        []
                    , Html.button [ Html.Events.onClick UserClickedSubmit ] [ Html.text "Next" ]
                    ]
                ]

            End ->
                [ Html.h1 [] [ Html.text "End" ]
                ]
        )
            ++ [ Html.ul []
                    (Dict.toList model.form
                        |> List.map (\( key, value ) -> Html.li [] [ Html.text (key ++ ": " ++ value) ])
                    )
               ]
    }
