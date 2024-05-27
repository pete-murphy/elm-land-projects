module Store.Msg exposing (..)

import Api.Author as Author exposing (Author)
import Api.Image exposing (Image)
import Api.Post exposing (Post)
import Http
import Store.Action exposing (Action)


type Msg
    = GotActions (List Action)
    | GotErrorFor Action Http.Error
      --
    | GotAuthor (Author Author.Full)
    | GotAuthors (List (Author Author.Preview))
    | GotPost Post
    | GotPosts (List Post)
    | GotImage Image
      --
    | NoOp
