module Page.Vote exposing (..)

import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Dict
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
    choices: Dict.Dict String Int
  }

type alias PollResponse =
  { title: String,
    choices: List String
  }

init : Int -> ( Model, Cmd Msg )
init id = 
  let model = Model id (Poll "" Dict.empty)
  in ( model, getPollRequest model )



-- UPDATE
type Msg 
  = GetPollResponse (Result Http.Error PollResponse)
  | ChangeRank String String
  | SubmitVoteRequest
  | SubmitVoteResponse (Result Http.Error ())

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok pollResponse ->
          let 
            indexedChoices = List.indexedMap (\x y -> ( y , x )) pollResponse.choices
            choicesDict = Dict.fromList indexedChoices
            newPoll = Poll pollResponse.title choicesDict
          in ( { model | poll = newPoll }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

    ChangeRank choice rank ->
      case String.toInt rank of
          Just newRank ->
            let 
              newChoices = model.poll.choices |> Dict.update choice (Maybe.map <| \_ -> newRank)
              oldPoll = model.poll
              newPoll = { oldPoll | choices = newChoices }
            in ( { model | poll = newPoll }, Cmd.none)
            
          Nothing ->
            ( model, Cmd.none )

    SubmitVoteRequest ->
        ( model, submitVoteRequest model) 

    SubmitVoteResponse result ->
      case result of
        Ok _ ->
          (model, Navigation.load ("/poll/" ++ String.fromInt model.id) )

        Err _ ->
          ( model, Cmd.none )
      
getPollRequest : Model -> Cmd Msg
getPollRequest model =
  Http.get
    { url = "http://localhost:4000/poll/" ++ String.fromInt model.id
    , expect = Http.expectJson GetPollResponse getPollDecoder
    }

getPollDecoder : Decode.Decoder PollResponse
getPollDecoder =
  Decode.map2 PollResponse
    (Decode.field "data" (Decode.field "title" Decode.string))
    (Decode.field "data" (Decode.field "choices" (Decode.list Decode.string)))

submitVoteRequest : Model -> Cmd Msg
submitVoteRequest model =
  Http.post
    { url = "http://localhost:4000/vote/"
    , body = Http.jsonBody (submitVoteJson model)
    , expect = Http.expectWhatever SubmitVoteResponse
    }

submitVoteJson : Model -> Encode.Value
submitVoteJson model = 
  let stringChoices = Dict.map (\_ value -> String.fromInt value) model.poll.choices 
  in 
  Encode.object
    [ ( "poll_id", Encode.string <| String.fromInt model.id )
    , ( "choices", Encode.dict identity Encode.string stringChoices )
    ]



-- VIEW
view : Model -> Html Msg
view model =
  div []
    ( List.concat 
      [ [ div [ class "fv-main-text" ]
            [ text "-- Submit a vote by rearranging the choices below by preference." ]
        , h1 [ placeholder "Title" ] [ text model.poll.title ]
        ]

      , List.map renderChoice (Dict.toList model.poll.choices)

      , [ button [ onClick SubmitVoteRequest ] [ text "Submit Vote" ] ]
      ]
    )

renderChoice : ( String, Int ) -> Html Msg
renderChoice ( choice, rank ) =
  div []
    [ h2 [ style "display" "inline" ] [ text choice ]
    , input 
        [ placeholder "Enter rank in here"
        , value (String.fromInt rank)
        , onInput (ChangeRank choice) 
        , type_ "number"
        ] []
    ]