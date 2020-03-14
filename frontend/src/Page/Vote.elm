module Page.Vote exposing ( .. )

import Browser.Navigation as Navigation
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Dict
import Http
import Http.Detailed
import Json.Decode as Decode
import Json.Encode as Encode



-- MODEL
type alias Model = 
  { key: Navigation.Key
  , id: Int
  , poll: Poll
  , apiAddress: String
  , error : String
  , showError: Bool
  }

type alias Poll =
  { title: String
  , orderedChoices: Dict.Dict Int String
  , unorderedChoices: List String
  }

type alias PollResponse =
  { title: String
  , choices: List String
  }

init : Navigation.Key -> Int -> String -> ( Model, Cmd Msg )
init key id apiAddress = 
  let model = Model key id ( Poll "" Dict.empty [] ) apiAddress "" False
  in ( model, getPollRequest model )



-- UPDATE
type Msg 
  = GetPollResponse ( Result Http.Error PollResponse )
  | ChangeRank String String
  | SubmitVoteRequest
  | SubmitVoteResponse ( Result ( Http.Detailed.Error String ) ( Http.Metadata, String ) )
  | GoToPoll

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok pollResponse ->
          let 
            unorderedChoices = pollResponse.choices
            newPoll = Poll pollResponse.title Dict.empty unorderedChoices
          in ( { model | poll = newPoll }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

    ChangeRank choice rank ->
      let
        oldPoll = model.poll
        ( newOrdered, newUnordered ) = changeRank rank choice oldPoll.orderedChoices oldPoll.unorderedChoices
        newPoll = { oldPoll | orderedChoices = newOrdered, unorderedChoices = newUnordered }
      in ( { model | poll = newPoll, showError = False }, Cmd.none)
      
    SubmitVoteRequest ->
        ( model, submitVoteRequest model) 

    SubmitVoteResponse result ->
      case result of
        Ok _ ->
          ( model, Navigation.pushUrl model.key ( "/poll/" ++ String.fromInt model.id ) )

        Err error ->
          let 
            newError =
              case error of
                Http.Detailed.BadStatus _ body ->
                  body
                _ ->
                  "Unable to submit vote. The website may be down for maintenace. Please try again later."
          in
          ( { model | showError = True, error = newError }, Cmd.none )
    
    GoToPoll ->
      ( model, Navigation.load ( "/poll/" ++ String.fromInt model.id ) )

calculateMaxRank : Dict.Dict Int String -> List String -> Int
calculateMaxRank ordered unordered =
  Dict.size ordered + List.length unordered

changeRank : String -> String -> Dict.Dict Int String -> List String -> ( Dict.Dict Int String, List String )
changeRank rank choice ordered unordered  =
  let
    maxRank = calculateMaxRank ordered unordered
    -- Remove from choices
    filteredOrdered = Dict.filter ( \_ v -> v /= choice ) ordered
    filteredUnordered = List.filter ( \v -> v /= choice ) unordered
  in
  case String.toInt rank of
    Nothing ->
      let
        -- Add into unordered
        addedUnordered = filteredUnordered ++ [ choice ]
      in ( filteredOrdered, addedUnordered )
    Just newRank ->
      let
        -- Update choices with new rankings
        ( updatedOrdered, updatedUnordered ) = updateChoices 0 True maxRank newRank filteredOrdered Dict.empty filteredUnordered 
        -- Add new rank into ordered
        addedOrdered = Dict.insert newRank choice updatedOrdered
      in ( addedOrdered, updatedUnordered )

updateChoices : Int -> Bool -> Int -> Int -> Dict.Dict Int String -> Dict.Dict Int String -> List String -> ( Dict.Dict Int String, List String )
updateChoices index canFill maxRank rank ordered newOrdered newUnordered = 
  if index > maxRank then
    ( newOrdered, newUnordered )
  else 
    case Dict.get index ordered of
      Nothing ->
        let 
          newCanFill = 
            if not canFill then
              False
            else 
              index < rank
        in updateChoices ( index + 1 ) newCanFill maxRank rank ordered newOrdered newUnordered
      Just choice ->
        let updateChoicesHelp = updateChoices ( index + 1 ) canFill maxRank rank ordered
        in
        if not canFill || index < rank then
          updateChoicesHelp ( Dict.insert index choice newOrdered ) newUnordered
        -- Add to unordered if we need to bump the last ordered choice
        else if index == maxRank then
          updateChoicesHelp newOrdered ( newUnordered ++ [ choice ] )
        else
          updateChoicesHelp ( Dict.insert ( index + 1 ) choice newOrdered ) newUnordered

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
    , expect = Http.Detailed.expectString SubmitVoteResponse
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
  let 
    maxRank = calculateMaxRank model.poll.orderedChoices model.poll.unorderedChoices
    hasOrderedChoices = not <| Dict.isEmpty model.poll.orderedChoices 
  in
  div []
    [ div 
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
        ( List.indexedMap ( renderOrderedChoice maxRank model.showError ) <| Dict.toList model.poll.orderedChoices )

      , div
        [ class "fv-main-code text-center w-full py-1" ] 
        [ text "--" ]

    , div []
        ( List.indexedMap ( renderUnorderedChoice maxRank hasOrderedChoices model.showError ) <| model.poll.unorderedChoices )

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

    , div 
        [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]
        , div [ class "w-full fv-main-text fv-main-text-error" ] [ errorText model.error ] 
        , div [ class "w-8 text-right" ] [ text "" ]
        ]

    , div
        [ class "fv-main-code text-center w-full my-3" ] 
        [ text "--" ]
    
    , div
        [ class "fv-main-text mb-2" ]
        [ text "-- View the poll results." ]
      
    , div 
        [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]
        , button 
          [ class "fv-main-btn mb-2 bg-gray-900 text-orange-500 border-2 border-orange-500"
          , onClick GoToPoll
          ] 
          [ text "View Results" ]
        , div [ class "w-8 text-right" ] [ text "" ]
        ]
    ]

renderOrderedChoice : Int -> Bool -> Int -> ( Int, String ) -> Html Msg
renderOrderedChoice maxRank showError index ( rank, choice ) =
  renderChoice maxRank False showError index ( String.fromInt rank, choice )

renderUnorderedChoice : Int -> Bool -> Bool -> Int -> String -> Html Msg
renderUnorderedChoice maxRank hasOrderedChoices showError index choice  =
  renderChoice maxRank hasOrderedChoices showError index ( "--", choice )

renderChoice : Int -> Bool -> Bool -> Int -> ( String, String ) -> Html Msg
renderChoice maxRank hasOrderedChoices showError index ( rank, choice ) =
  div 
    [ class "flex justify-between items-center" ]
    [ div 
      [ class "fv-main-code w-8"] 
      [ unorderedCommaText hasOrderedChoices index
      , text "(" 
      ]

    , div 
        [ class "flex items-center w-full p-2" 
        , textColorClass index
        , borderClass index maxRank 
        ]
        [ select 
            [ class "fv-main-input w-auto"
            , errorClass showError
            , value rank
            , onChange ( ChangeRank choice )
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

{-
See: https://package.elm-lang.org/packages/elm/html/latest/Html-Events#targetValue
There is an issue where select onInput does not work
in production. I'm not exactly sure why, but this is 
an attempt to use the on changer handler instead of
onInput for more consistent results.
-}
onChange : ( String -> msg ) -> Html.Attribute msg
onChange tagger =
  stopPropagationOn "change" <| Decode.map alwaysStop ( Decode.map tagger Html.Events.targetValue )

alwaysStop : a -> (a, Bool)
alwaysStop x =
  (x, True)

renderOptions : Int -> List ( Html Msg )
renderOptions maxRank = 
  List.map renderOption <| List.range 1 maxRank

renderOption : Int -> Html Msg
renderOption rank =
  option [ value <| String.fromInt rank ] [ text <| String.fromInt rank ]

unorderedCommaText : Bool -> Int -> Html a
unorderedCommaText hasOrderedChoices index = 
  if hasOrderedChoices || index > 0 then
    text ","
  else 
    text ""

textColorClass : Int -> Attribute a
textColorClass index = 
  if modBy 2 index == 0 then
    class "bg-blue-800"
  else
    class "bg-blue-900"

borderClass : Int -> Int -> Attribute a
borderClass index maxRank =
  if index == 0 then
    class "rounded-t-sm"
  else if index == maxRank - 1 then
    class "rounded-b-sm shadow-lg"
  else
    class ""

errorClass : Bool -> Attribute a
errorClass showError =
  if showError then
    class "fv-main-input-error"
  else
    class ""

errorText : String -> Html a
errorText error =
  if String.isEmpty error then
    text ""
  else
    text <| "-- " ++ error