module Components.PostList exposing (view)

import Api.Data
import Api.Post exposing (Post)
import Api.PostId as PostId
import CustomElements
import Html exposing (Html)
import Html.Attributes as Attributes
import Route.Path


view : List (Api.Data.Data Post) -> Html msg
view posts =
    let
        viewPost : Post -> Html msg
        viewPost post =
            Html.li
                []
                [ Html.a
                    [ Attributes.class "grid gap-1 py-2 px-4 bg-white rounded-lg shadow-sm"
                    , Route.Path.href (Route.Path.Posts_PostId_ { postId = PostId.toString post.id })
                    ]
                    [ Html.div
                        [ Attributes.class "grid grid-flow-col gap-3 items-baseline grid-cols-[auto_minmax(max-content,1fr)_auto]" ]
                        [ Html.span [ Attributes.class "text-lg font-bold line-clamp-1" ] [ Html.text post.title ]
                        , Html.span [ Attributes.class "" ] [ Html.text post.authorName ]
                        , Html.span [ Attributes.class "flex gap-2 text-sm text-slate-500" ]
                            [ Html.span [] [ Html.text "📆" ]
                            , Html.span [ Attributes.class "line-clamp-1" ] [ CustomElements.relativeTime post.createdAt ]
                            ]
                        ]
                    , Html.div
                        [ Attributes.class "text-sm line-clamp-2" ]
                        [ Html.text post.content ]
                    ]
                ]
    in
    Html.ul [ Attributes.class "gap-2 dg dg-min-cols-1 dg-col-min-w-[48ch] dg-max-cols-4" ]
        (posts |> List.map (Api.Data.view_ viewPost))
