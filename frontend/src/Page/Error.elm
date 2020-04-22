module Page.Error exposing ( .. )

import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )



view : Html a
view =
  div []
    [ div [ class "flex justify-between" ]
        [ div [ class "fv-code w-8" ] [ text "{-" ]
        , h1 [ class "fv-header" ] [ text "Error" ]
        , div [ class "w-8 text-right" ] [ text "" ]
        ]

    ,  div [ class "fv-text mb-2" ]
      [ text "Hmm, this page doesn’t seem to exist, or maybe we encountered an error. Feel free to "
      , a [ href "https://twitter.com/FunctionalVote"
          , target "_blank"
          ] [ text "contact us"]
      , text " if you are experiencing any issues." ]

    , div [ class "fv-code mb-1" ] [ text "-}" ]

    , div [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]
        , a
            [ class "fv-btn"
            , href "/"
            ]
            [ text "Go Home" ]
        , div [ class "w-8 text-right" ] [ text "" ]
        ]
    ]