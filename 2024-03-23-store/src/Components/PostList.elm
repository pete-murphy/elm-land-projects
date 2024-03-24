module Components.PostList exposing (view)

import Api.Post exposing (Post)
import CustomElements
import Html exposing (Html)
import Html.Attributes as Attributes


view : List Post -> Html msg
view posts =
    let
        viewPost post =
            Html.li [ Attributes.class "grid gap-1 py-2 px-4 bg-white rounded-lg shadow-sm" ]
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
    in
    Html.ul [ Attributes.class "gap-2 dg dg-min-cols-1 dg-col-min-w-[48ch] dg-max-cols-4" ]
        (posts |> List.map viewPost)
