module Page.Error exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



-- VIEW
view : Html a
view =
  div [] 
    [ h1 [ class "fv-main-header" ]
      [ text "Error" ]
    ,  div [ class "fv-main-text pb-6" ]
      [ text "-- Hmm, this page doesn’t seem to exist, or maybe we encountered an error. Feel free to "
      , a [ href "https://twitter.com/FunctionalVote" ] [ text "contact us"]
      , text " if you’re experiencing any issues." ]
    , button 
        [ class "fv-main-btn"
        ]
        [ text "Go Home" ] 
    ]