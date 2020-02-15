module Page.Poll exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array exposing (..)



-- MODEL
type alias Model = 
  { id: Int }

init : Int -> ( Model, Cmd Msg )
init id = 
  ( Model id, Cmd.none )



-- UPDATE
type Msg 
  = PollTest

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PollTest ->
      (model, Cmd.none)



-- VIEW
view : Model -> Html Msg
view model =
  div [] [ text ("I am poll " ++ String.fromInt model.id) ]