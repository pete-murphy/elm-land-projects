module Store.Msg exposing (..)

import Api.Author as Author exposing (Author)
import Api.AuthorId as AuthorId exposing (AuthorId)
import Api.Data
import Api.Image as Image exposing (Image)
import Api.ImageId as ImageId exposing (ImageId)
import Api.Post exposing (Post)
import Api.PostId as PostId exposing (PostId)
import Http
import RemoteData exposing (RemoteData(..))
import Result.Extra
import Store.Action exposing (Action)


type Msg
    = GotActions (List Action)
    | GotErrorFor Action Http.Error
      --
    | GotAuthor (Author Author.Full) (List Action)
    | GotAuthors (List (Author Author.Preview))
    | GotPost Post (List Action)
    | GotPosts (List Post)
    | GotImage Image
      --
    | NoOp
