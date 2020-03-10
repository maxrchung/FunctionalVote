module Page.Vote exposing (..)

import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Dict
import Set
import Http
import Json.Decode as Decode
import Json.Encode as Encode



-- MODEL
type alias Model = 
  { id: Int
  , poll: Poll
  , apiAddress: String
  }

type alias Poll =
  { title: String
  , orderedChoices: Dict.Dict Int String
  , unorderedChoices: Set.Set String
  }

type alias PollResponse =
  { title: String
  , choices: List String
  }

init : Int -> String -> ( Model, Cmd Msg )
init id apiAddress = 
  let model = Model id ( Poll "" Dict.empty Set.empty ) apiAddress
  in ( model, getPollRequest model )



-- UPDATE
type Msg 
  = GetPollResponse (Result Http.Error PollResponse)
  | ChangeRank Int String
  | SubmitVoteRequest
  | SubmitVoteResponse (Result Http.Error ())

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok pollResponse ->
          let 
            unorderedChoices = Set.fromList pollResponse.choices
            newPoll = Poll pollResponse.title Dict.empty unorderedChoices
          in ( { model | poll = newPoll }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

    ChangeRank rank choice ->
        let
          oldPoll = model.poll
          -- Remove from choices
          filteredOrdered = Dict.filter ( \_ v -> v == choice ) oldPoll.orderedChoices
          filteredUnordered = Set.remove choice oldPoll.unorderedChoices
          -- Update choices with new rankings
          ( updatedOrdered, newUnordered ) = updateChoices rank choice filteredOrdered filteredUnordered
          -- Add into ordered
          newOrdered = Dict.insert  updatedOrdered
          newPoll = { oldPoll | orderedChoices = newOrdered, unorderedChoices = newUnordered }
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
    { url = model.apiAddress ++ "/poll/" ++ String.fromInt model.id
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
    { url = model.apiAddress ++ "/vote/"
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
    [ div
        [ class "fv-main-text pb-2" ]
        [ text "-- View the poll results." ]
      
    , div 
        [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]
        , button 
          [ class "fv-main-btn mb-2 bg-gray-900 text-orange-500 border-2 border-orange-500"
          , onClick SubmitVoteRequest
          ] 
          [ text "View Results" ]
        , div [ class "w-8 text-right" ] [ text "" ]
        ]
    

    , div
        [ class "fv-main-code text-center w-full" ] 
        [ text "--" ]
      
    , div 
        [ class "fv-main-text" ]
        [ text "-- Submit a new vote below by selecting ranks to the left of each choice." ]

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
        [ class "flex justify-between items-center" ]
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

    , div []
        ( List.indexedMap ( renderChoice choicesSize ) <| Dict.toList model.poll.choices )

    , div [class "fv-main-code pb-2" ] [ text "]}" ]
      
    , div 
        [ class "flex justify-between pb-1" ]
        [ div [ class "w-8" ] [ text "" ]
        , button 
            [ class "fv-main-btn"
            , onClick SubmitVoteRequest
            ] 
            [ text "Submit Vote" ] 
        , div [ class "w-8 text-right" ] [ text "" ]
        ]
    ]



renderChoice : Int -> Int -> ( String, String ) -> Html Msg
renderChoice choicesSize index ( choice, rank ) =
  let 
    textColorClass = 
      if modBy 2 index == 0 then
        class "bg-blue-800"
      else
        class "bg-blue-900"

    borderClass =
      if index == 0 then
        class "rounded-t-sm"
      else if index == choicesSize - 1 then
        class "rounded-b-sm shadow-lg"
      else
        class ""
  in
  div 
    [ class "flex justify-between items-center" ]
    [ div [ class "fv-main-code w-8"] [ text "(" ]

    , div 
        [ class "flex items-center w-full p-2" 
        , textColorClass 
        , borderClass ]
        [ select 
            [ class "fv-main-input w-auto"
            , value rank
            , onInput ( ChangeRank choice ) 
            ] 

            ( List.concat
              [ renderOptions choicesSize
              , [ option 
                  [ value "--"
                  , selected True 
                  ]
                  [ text "--" ]
                ]
              ]
            )

        , div 
            [ class "fv-main-code w-8 text-center" ] 
            [ text ",\"" ]

        , div 
            [ class "fv-main-text text-blue-100 w-full" ]
            [ text choice ]
        ]

    , div [class "fv-main-code w-8 text-right" ] [ text "\")" ]
    ]

renderOptions : Int -> List ( Html Msg )
renderOptions choicesSize = 
  List.map renderOption <| List.range 1 choicesSize

renderOption : Int -> Html Msg
renderOption rank =
  option [ value <| String.fromInt rank ] [ text <| String.fromInt rank ]