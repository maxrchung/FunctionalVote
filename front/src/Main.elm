module Main exposing (..)
import Browser
import Html exposing (Html, Attribute, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)

-- MAIN
main = Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type alias Model = { title : String }

init : Model
init = Model ""

-- UPDATE
type Msg 
    = ChangeTitle String

update : Msg -> Model -> Model
update msg model =
  case msg of
    ChangeTitle newTitle ->
      { model | title = newTitle }

-- VIEW
view : Model -> Html Msg
view model =
  div []
    [ input [ placeholder "Title", value model.title, onInput ChangeTitle ] []
    ]