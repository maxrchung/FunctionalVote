
module Shared exposing ( .. )

import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )

renderShareLinks : String -> String -> Html a
renderShareLinks url description =
  div []
    [ div
        [ class "fv-break" ] 
        [ text "--" ]

    , div
        [ class "fv-main-text mb-2" ]
        [ text description ]

    , div 
        [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]

        , div
            [ class "w-full" ]
            [ div 
                [ class "flex justify-between w-full" ]
                [ div 
                    [ class "w-8 text-blue-500" ] 
                    [ renderIcon FeatherIcons.share ]

                , div
                    [ class "flex-grow bg-orange-900" ]
                    [ text "asdf" ]

                , div 
                    [ class "w-8 text-orange-500" ] 
                    [ renderIcon FeatherIcons.clipboard ]
                ]
            
            , div 
                [ class "flex justify-between w-full" ]
                [ div 
                    [ class "w-8 text-blue-500" ] 
                    [ renderIcon FeatherIcons.facebook ]

                , div
                    [ class "flex-grow bg-orange-900" ]
                    [ text "asdf" ]

                , div 
                    [ class "w-8 text-orange-500" ] 
                    [ renderIcon FeatherIcons.clipboard ]
                ]

            , div 
                [ class "flex justify-between w-full" ]
                [ div 
                    [ class "w-8 text-blue-500" ] 
                    [ renderIcon FeatherIcons.twitter ]

                , div
                    [ class "flex-grow bg-orange-900" ]
                    [ text "asdf" ]

                , div 
                    [ class "w-8 text-orange-500" ] 
                    [ renderIcon FeatherIcons.clipboard ]
                ]
            ]
          
        , div [ class "w-8 text-right" ] [ text "" ]
        ]
    ]


renderIcon : FeatherIcons.Icon -> Html a
renderIcon icon =
  icon
    |> FeatherIcons.withSize 22
    |> FeatherIcons.toHtml []