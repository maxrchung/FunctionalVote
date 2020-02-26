module Page.Error exposing (..)

import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



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
    [ h1 [ class "fv-main-header" ]
      [ text "Error" ]
    ,  div [ class "fv-main-text pb-6" ]
      [ text "-- Hmm, this page doesn’t seem to exist, or maybe we encountered an error. Feel free to "
      , a [ href "https://twitter.com/FunctionalVote" ] [ text "contact us"]
      , text " if you’re experiencing any issues." ]
    , button 
        [ class "fv-main-btn"
        , onClick GoToHome
        ]
        [ text "Go Home" ] 
    ]