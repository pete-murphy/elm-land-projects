module Store.Action exposing (..)

import Api.Author as Author exposing (Author)
import Api.AuthorId exposing (AuthorId)
import Api.ImageId exposing (ImageId)
import Api.Post exposing (Post)
import Api.PostId exposing (PostId)
import RemoteData exposing (RemoteData(..))


type Action
    = GetPosts
    | GetPostById PostId (Post -> List Action)
    | GetAuthors
    | GetAuthorById AuthorId (Author Author.Full -> List Action)
    | GetImageById ImageId
