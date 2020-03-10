module Page.Poll exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode



-- MODEL
type alias Model = 
  { id: Int
  , poll: Poll
  , apiAddress: String
  }

type alias Poll =
  { title: String
  , choices: List String
  , winner: String
  }

init : Int -> String -> ( Model, Cmd Msg )
init id apiAddress = 
  let model = Model id (Poll "" [] "" ) apiAddress
  in ( model, getPollRequest model )



-- UPDATE
type Msg 
  = GetPollResponse (Result Http.Error Poll)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok newPoll ->
          ( { model | poll = newPoll }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

getPollRequest : Model -> Cmd Msg
getPollRequest model =
  Http.get
    { url = model.apiAddress ++ "/poll/" ++ String.fromInt model.id
    , expect = Http.expectJson GetPollResponse getPollDecoder
    }

getPollDecoder : Decode.Decoder Poll
getPollDecoder =
  Decode.map3 Poll
    (Decode.field "data" (Decode.field "title" Decode.string))
    (Decode.field "data" (Decode.field "choices" (Decode.list Decode.string)))
    (Decode.field "data" (Decode.field "winner" Decode.string))



-- VIEW
view : Model -> Html Msg
view model =
  div [] 
    ( [ h1 [ placeholder "Title" ] [ text model.poll.title ] ] ++

      List.map (renderChoice model.poll.winner) model.poll.choices
    )

renderChoice : String -> String -> Html Msg
renderChoice winner choice =
  if winner == choice then
    h2 [] [ text <| "Winner: " ++ choice ]
  else
    div [] [ text choice]