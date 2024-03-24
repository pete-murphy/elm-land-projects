module Play exposing (..)

import Accessibility as Html exposing (Html)
import Api.Author as Author exposing (Author(..))
import Api.Post as Post
import Browser
import Pages.Home_ as Home
import RemoteData exposing (RemoteData(..))


main : Program () Home.Model Home.Msg
main =
    Browser.element
        { init = init
        , view = Home.view >> .body >> Html.div []
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : any -> ( Home.Model, Cmd msg )
init _ =
    ( { authors = Success Author.exampleGetAll
      , posts = Success Post.exampleGetAll
      }
    , Cmd.none
    )



-- Html.div []
--     [ Html.h1 [] [ Html.text "Playground" ]
--     , Home.viewAuthors Author.exampleGetAll
--     , Home.viewPosts []
--     ]
-- update : () -> msg -> ( (), Cmd msg )


update _ model =
    ( model, Cmd.none )
