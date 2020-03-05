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
    choices: Dict.Dict String String
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
            indexedChoices = List.map (\choice -> ( choice, "--" )) pollResponse.choices
            choicesDict = Dict.fromList indexedChoices
            newPoll = Poll pollResponse.title choicesDict
          in ( { model | poll = newPoll }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

    ChangeRank choice rank ->
        let 
          newChoices = model.poll.choices |> Dict.update choice (Maybe.map <| \_ -> rank)
          oldPoll = model.poll
          newPoll = { oldPoll | choices = newChoices }
        in ( { model | poll = newPoll }, Cmd.none)

    SubmitVoteRequest ->
        ( model, submitVoteRequest model) 

    SubmitVoteResponse result ->
      case result of
        Ok _ ->
          ( model, Navigation.load ( "/poll/" ++ String.fromInt model.id ) )

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
  Encode.object
    [ ( "poll_id", Encode.string <| String.fromInt model.id )
    , ( "choices", Encode.dict identity Encode.string model.poll.choices )
    ]



-- VIEW
view : Model -> Html Msg
view model =
  let choicesSize = Dict.size model.poll.choices
  in
  div []
    ( List.concat 
      [ 
        [ div 
            [ class "fv-main-text" ]
            [ text "-- Rank the choices below by selecting a preference to the left of each choice." ]

        , div 
            [ class "flex justify-between" ]
            [ h1 [ class "fv-main-code" ] [ text "vote" ]
            , div [ class "fv-main-code" ] [ text "={" ]
            ]
        
        , div 
            [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "fv-main-header" ] [ text "Question" ]
            , div [ class "fv-main-code w-8 text-right" ] [ text "=" ]
            ]

        , div 
            [ class "flex justify-between items-center pb-1" ]
            [ div [ class "fv-main-code w-8"] [ text "\"" ]
            , div 
              [ class "flex justify-center w-full"]
              [ h1 
                [ class "fv-main-text text-blue-100 text-left" 
                , placeholder "Title" ] 
                [ text model.poll.title ]
              ]
            , div [class "fv-main-code w-8 text-right" ] [ text "\"" ]
            ]

        , div [ class "fv-main-code" ] [ text "," ]

        , div 
            [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "fv-main-header" ] [ text "Ranks" ]
            , div [ class "fv-main-code w-8 text-right" ] [ text "=[" ]
            ]
        ]

      , List.indexedMap ( renderChoice choicesSize ) <| Dict.toList model.poll.choices 

      , [ div [class "fv-main-code pb-2" ] [ text "]}" ]
        
        , button 
            [ class "fv-main-btn"
            , onClick SubmitVoteRequest
            ] 
            [ text "Submit Vote" ] 
        ]
      ]
    )

renderChoice : Int -> Int -> ( String, String ) -> Html Msg
renderChoice choicesSize index ( choice, rank ) =
  let 
    textColorClass = 
      if modBy 2 index == 0 then
        class "text-blue-100"
      else
        class "text-blue-300"
  in
  div 
    [ class "flex justify-between items-center pb-2" ]
    [ div [ class "fv-main-code w-8"] [ text "(" ]

    , div 
        [ class "flex items-center w-full" ]
        [ select 
            [ class ""
            , value rank
            , onInput ( ChangeRank choice ) 
            ] 
            [ option 
              [ value "--"
              , selected True 
              ]
              [ text "--" ]
            , option [ value "1" ] [ text "1" ]
            , option [ value "2" ] [ text "2" ]
            , option [ value "3" ] [ text "3" ]
            ]

        , div [class "fv-main-code w-8 text-center " ] [ text ",\"" ]

        , div 
            [ class "fv-main-text w-full" 
            , textColorClass ]
            [ text choice ]
        ]

    , div [class "fv-main-code w-8 text-right" ] [ text "\")" ]
    ]


 