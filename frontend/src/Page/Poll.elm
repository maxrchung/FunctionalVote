module Page.Poll exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array exposing (..)

-- MODEL
type alias Model = 
  { id: String }

-- UPDATE
type Msg 
  = PollTest

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PollTest ->
      (model, Cmd.none)

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

-- VIEW
view : Model -> Html Msg
view model =
  div [] [ text ("I am poll " ++ model.id) ]