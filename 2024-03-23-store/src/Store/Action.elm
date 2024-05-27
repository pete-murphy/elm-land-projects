module Store.Action exposing (..)

import Api.AuthorId exposing (AuthorId)
import Api.ImageId exposing (ImageId)
import Api.PostId exposing (PostId)


type Action
    = GetPosts
    | GetPostById PostId
    | GetAuthors
    | GetAuthorById AuthorId
    | GetImageById ImageId
