module Page.Error exposing ( .. )

import Browser.Navigation as Navigation
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )



type alias Model = { key : Navigation.Key }

init : Navigation.Key -> ( Model, Cmd Msg )
init key = ( Model key, Cmd.none )



-- UPDATE
type Msg 
  = GoToHome

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GoToHome ->
      ( model, Navigation.pushUrl model.key "/" )

-- VIEW
view : Model -> Html Msg
view _ =
  div [] 
    [ div [ class "fv-main-code" ] [ text "{-" ]
      
    , h1 [ class "fv-main-header" ]
      [ text "Error" ]

    ,  div [ class "fv-main-text mb-2" ]
      [ text "Hmm, this page doesn’t seem to exist, or maybe we encountered an error. Feel free to "
      , a [ href "https://twitter.com/FunctionalVote" 
          , target "_blank"
          ] [ text "contact us"]
      , text " if you’re experiencing any issues." ]

    , div [ class "fv-main-code mb-1" ] [ text "-}" ]

    , button 
        [ class "fv-main-btn"
        , onClick GoToHome
        ]
        [ text "Go Home" ] 
    ]