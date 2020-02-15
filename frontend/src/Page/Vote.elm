module Page.Vote exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array exposing (..)

-- MODEL
type alias Model = 
  { id: String }

-- UPDATE
type Msg 
  = VoteTest

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    VoteTest ->
      (model, Cmd.none)



-- VIEW
view : Model -> Html Msg
view model =
  div [] [ text ("I am vote " ++ model.id) ]