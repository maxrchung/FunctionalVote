module Main exposing (..)
import Browser
import Html exposing (Html, Attribute, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Array exposing (..)

-- MAIN
main = Browser.sandbox { init = init, update = update, view = view }

-- MODEL
type alias Model = 
    { title : String
    , choices : Array String }

init : Model
init = Model "" (Array.fromList ["1", "2", "3"])

-- UPDATE
type Msg 
    = ChangeTitle String
    | ChangeChoice Int String

update : Msg -> Model -> Model
update msg model =
  case msg of
    ChangeTitle newTitle ->
        { model | title = newTitle }
    ChangeChoice index newChoice ->
        { model | choices = Array.set index newChoice model.choices }

-- VIEW
view : Model -> Html Msg
view model =
  div []
    ([ input [ placeholder "Title", value model.title, onInput ChangeTitle ] [] ] ++
    Array.toList (Array.indexedMap renderChoice model.choices))


renderChoice : Int -> String -> Html Msg
renderChoice index choice =
    input [ placeholder "Choice", value choice, onInput (ChangeChoice index) ] []