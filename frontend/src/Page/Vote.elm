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
  , maxRank: Int
  }

type alias PollResponse =
  { title: String
  , choices: List String
  }

init : Int -> String -> ( Model, Cmd Msg )
init id apiAddress = 
  let model = Model id ( Poll "" Dict.empty Set.empty 0 ) apiAddress
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
            unorderedChoices = Set.fromList pollResponse.choices
            maxRank = Set.size unorderedChoices 
            newPoll = Poll pollResponse.title Dict.empty unorderedChoices maxRank
          in ( { model | poll = newPoll }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

    ChangeRank rank choice ->
      let
        oldPoll = model.poll

        -- Remove from choices
        filteredOrdered = Dict.filter ( \_ v -> v == choice ) oldPoll.orderedChoices
        filteredUnordered = Set.remove choice oldPoll.unorderedChoices
      in
      case String.toInt rank of
        Nothing ->
          let
            -- Add into unordered
            addedUnordered = Set.insert choice filteredUnordered
            newPoll = { oldPoll | orderedChoices = filteredOrdered, unorderedChoices = addedUnordered }
          in ( { model | poll = newPoll }, Cmd.none)
        Just newRank ->
          let
            -- Update choices with new rankings
            ( updatedOrdered, updatedUnordered ) = updateChoices 0 True oldPoll.maxRank newRank filteredOrdered Dict.empty filteredUnordered 
            -- Add new rank into ordered
            addedOrdered = Dict.insert newRank choice updatedOrdered
            newPoll = { oldPoll | orderedChoices = addedOrdered, unorderedChoices = updatedUnordered }
          in ( { model | poll = newPoll }, Cmd.none)

    SubmitVoteRequest ->
        ( model, submitVoteRequest model) 

    SubmitVoteResponse result ->
      case result of
        Ok _ ->
          ( model, Navigation.load ( "/poll/" ++ String.fromInt model.id ) )

        Err _ ->
          ( model, Cmd.none )
      
updateChoices : Int -> Bool -> Int -> Int -> Dict.Dict Int String -> Dict.Dict Int String -> Set.Set String -> ( Dict.Dict Int String, Set.Set String )
updateChoices index canFill maxRank rank ordered newOrdered newUnordered = 
  if index > maxRank then
    ( ordered, newUnordered )
  else 
    case Dict.get rank ordered of
      Nothing ->
        let 
          newCanFill =
            if canFill && index >= rank then
              False
            else
              True
        in updateChoices ( index + 1 ) newCanFill maxRank rank ordered newOrdered newUnordered
      Just choice ->
        let updateChoicesHelp = updateChoices ( index + 1 ) canFill maxRank rank ordered
        in
        if not canFill || index < rank then
          updateChoicesHelp ( Dict.insert rank choice newOrdered ) newUnordered
        -- Add to unordered if we need to bump the last ordered choice
        else if index == maxRank then
          updateChoicesHelp newOrdered ( Set.insert choice newUnordered )
        else
          updateChoicesHelp ( Dict.insert ( rank + 1 ) choice newOrdered ) newUnordered

getPollRequest : Model -> Cmd Msg
getPollRequest model =
  Http.get
    { url = model.apiAddress ++ "/poll/" ++ String.fromInt model.id
    , expect = Http.expectJson GetPollResponse getPollDecoder
    }

getPollDecoder : Decode.Decoder PollResponse
getPollDecoder =
  Decode.map2 PollResponse
    ( Decode.field "data" <| Decode.field "title" <| Decode.string )
    ( Decode.field "data" <| Decode.field "choices" <| Decode.list Decode.string )

submitVoteRequest : Model -> Cmd Msg
submitVoteRequest model =
  Http.post
    { url = model.apiAddress ++ "/vote/"
    , body = Http.jsonBody <| submitVoteJson model
    , expect = Http.expectWhatever SubmitVoteResponse
    }

submitVoteJson : Model -> Encode.Value
submitVoteJson model = 
  let
    choices =
      Dict.foldl buildSubmissionChoices Dict.empty model.poll.orderedChoices
  in
  Encode.object
    [ ( "poll_id", Encode.string <| String.fromInt model.id )
    , ( "choices", Encode.dict identity Encode.string choices )
    ]

buildSubmissionChoices : Int -> String -> Dict.Dict String String -> Dict.Dict String String
buildSubmissionChoices rank choice choices =
  Dict.insert choice ( String.fromInt rank ) choices



-- VIEW
view : Model -> Html Msg
view model =
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
        ( List.indexedMap ( renderOrderedChoice model.poll.maxRank ) <| Dict.toList model.poll.orderedChoices )

    , div []
        ( List.indexedMap ( renderUnorderedChoice model.poll.maxRank ) <| Set.toList model.poll.unorderedChoices )

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

renderOrderedChoice : Int -> Int -> ( Int, String ) -> Html Msg
renderOrderedChoice maxRank index ( rank, choice ) =
  renderChoice maxRank index ( String.fromInt rank, choice )

renderUnorderedChoice : Int -> Int -> String -> Html Msg
renderUnorderedChoice maxRank index choice  =
  renderChoice maxRank index ( "--", choice )

renderChoice : Int -> Int -> ( String, String ) -> Html Msg
renderChoice maxRank index ( rank, choice ) =
  let 
    textColorClass = 
      if modBy 2 index == 0 then
        class "bg-blue-800"
      else
        class "bg-blue-900"

    borderClass =
      if index == 0 then
        class "rounded-t-sm"
      else if index == maxRank - 1 then
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
              [ renderOptions maxRank
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
renderOptions maxRank = 
  List.map renderOption <| List.range 1 maxRank

renderOption : Int -> Html Msg
renderOption rank =
  option [ value <| String.fromInt rank ] [ text <| String.fromInt rank ]