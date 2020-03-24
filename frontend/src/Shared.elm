
module Shared exposing ( .. )

import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )

renderShareLinks : String -> String -> String -> String -> Html a
renderShareLinks url helpText title message =
  let
    twitterUrl = "https://twitter.com/intent/tweet?text=" ++ message ++ title ++ "&via=FunctionalVote&url=" ++ url
    facebookUrl = "https://www.facebook.com/sharer/sharer.php?u=" ++ url
    mailUrl = "mailto:?subject=Functional Vote - " ++ title ++ "&body=" ++ message ++ url
  in
  
  div []
    [ div
        [ class "fv-break" ] 
        [ text "--" ]

    , div
        [ class "fv-text mb-2" ]
        [ text helpText ]

    , div
        [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]

        , div
            [ class "w-full" ]
            [ div 
                [ class "flex justify-between items-center mb-4" ]
                [ div 
                    [ class "text-blue-500" ] 
                    [ renderIcon FeatherIcons.link ]

                , div
                    [ class "mx-2 flex-grow" ]
                    [ input
                        [ class "fv-input hover:bg-gray-900"
                        , disabled True
                        , value <| url
                        ]
                        []
                    ]

                , button 
                    [ class "w-10" ] 
                    []
                ]

            , div 
                [ class "flex justify-between items-center mb-4" ]
                [ div 
                    [ class "text-blue-500" ] 
                    [ renderIcon FeatherIcons.twitter ]

                , div
                    [ class "mx-2 flex-grow" ]
                    [ input
                        [ class "fv-input hover:bg-gray-900"
                        , disabled True
                        , value twitterUrl
                        ]
                        []
                    ]

                , a 
                    [ class "fv-nav-btn text-orange-500 bg-gray-900 border-2 border-orange-500 hover:text-orange-500 hover:bg-orange-900" 
                    , href <| twitterUrl
                    , target "_blank"
                    ]
                    [ renderIcon FeatherIcons.share ]
                ]

            , div 
                [ class "flex justify-between items-center mb-4" ]
                [ div 
                    [ class "text-blue-500" ] 
                    [ renderIcon FeatherIcons.facebook ]

                , div
                    [ class "mx-2 flex-grow" ]
                    [ input
                        [ class "fv-input hover:bg-gray-900"
                        , disabled True
                        , value <| facebookUrl
                        ]
                        []
                    ]

                , a 
                    [ class "fv-nav-btn text-orange-500 bg-gray-900 border-2 border-orange-500 hover:text-orange-500 hover:bg-orange-900"
                    , href facebookUrl
                    , target "_blank"
                    ]
                    [ renderIcon FeatherIcons.share ]
                ]

            , div 
                [ class "flex justify-between items-center" ]
                [ div 
                    [ class "text-blue-500" ] 
                    [ renderIcon FeatherIcons.mail ]

                , div
                    [ class "mx-2 flex-grow" ]
                    [ input
                        [ class "fv-input hover:bg-gray-900"
                        , disabled True
                        , value <| mailUrl
                        ]
                        []
                    ]

                , a 
                    [ class "fv-nav-btn text-orange-500 bg-gray-900 border-2 border-orange-500 hover:text-orange-500 hover:bg-orange-900" 
                    , href mailUrl
                    , target "_blank"
                    ]
                    [ renderIcon FeatherIcons.share ]
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