module Page.Vote exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode



-- MODEL
type alias Model = 
  { id: Int,
    poll: Poll
  }

type alias Poll =
  { title: String,
    choices: Array String
  }

init : Int -> ( Model, Cmd Msg )
init id = 
  ( Model id (Poll "" (Array.fromList [])), Cmd.none )



-- UPDATE
type Msg 
  = GetVoteResponse (Result Http.Error Poll)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetVoteResponse result ->
      case result of
        Ok newPoll ->
          ( { model | poll = newPoll }, Cmd.none )
        Err _ ->
          (model, Cmd.none)

getVoteRequest : Model -> Cmd Msg
getVoteRequest model =
  Http.get
    { url = "http://localhost:4000/vote/" ++ String.fromInt(model.id)
    , expect = Http.expectJson GetVoteResponse getVoteDecoder
    }

getVoteDecoder : Decode.Decoder Poll
getVoteDecoder =
  Decode.map2 Poll
    (Decode.field "data" (Decode.field "title" Decode.string))
    (Decode.field "data" (Decode.field "choices" (Decode.array Decode.string)))



-- VIEW
view : Model -> Html Msg
view model =
  div []
    ([ h1 [ placeholder "Title" ] [ text model.poll.title ] ] ++
    Array.toList (Array.indexedMap renderChoice model.poll.choices) ++
    [ button [] [ text "Submit Vote" ] ])

renderChoice : Int -> String -> Html Msg
renderChoice index choice =
  h2 [] [ text choice ]