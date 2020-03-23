
module Shared exposing ( .. )

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
        []
        [ 
        ]
    ]