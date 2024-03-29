port module Page.Vote exposing ( .. )

import Animation
import Browser.Dom as Dom
import Browser.Navigation as Navigation
import Dict
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Http.Detailed
import Json.Encode as Encode
import Page.Error
import Shared
import Task
import Time exposing ( Posix, Zone )



-- MODEL
type alias Model =
  { key : Navigation.Key
  , pollId : String
  , poll : Poll
  , apiAddress : String
  , error : String
  , showError : Bool
  , loadingState : LoadingState
  , fadeStyle : Animation.State
  , fadeChoice : String
  , recaptchaToken : String
  , env : String
  }

type alias Poll =
  { title : String
  , orderedChoices : Dict.Dict Int String
  , unorderedChoices : List String
  , useRecaptcha : Bool
  , created : String
  }

type LoadingState
  = Loaded
  | Error

init : Navigation.Key -> String -> String -> List String -> String -> Bool -> Posix -> Zone -> String -> LoadingState -> ( Model, Cmd Msg )
init key apiAddress title choices pollId useRecaptcha created timezone env loadingState =
  let
    cmd = if useRecaptcha then renderRecaptcha () else Cmd.none
    humanTimeString = Shared.toHumanTimeString created timezone
  in
  ( { key = key
    , pollId = pollId
    , poll = Poll title Dict.empty choices useRecaptcha humanTimeString
    , apiAddress = apiAddress
    , error = ""
    , showError = False
    , loadingState = loadingState
    , fadeStyle = Animation.style [ Animation.opacity 1.0 ]
    , fadeChoice = ""
    , recaptchaToken = ""
    , env = env
    }
  , cmd
  )



-- PORTS
port renderRecaptcha : () -> Cmd msg
port submitRecaptcha : ( String -> msg ) -> Sub msg


-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
      [ Animation.subscription Animate [ model.fadeStyle ]
      , submitRecaptcha RecaptchaToken
      ]



-- UPDATE
type Msg
  = ChangeRank String String
  | SubmitVoteRequest
  | SubmitVoteResponse ( Result ( Http.Detailed.Error String ) ( Http.Metadata, String ) )
  | Animate Animation.Msg
  | RecaptchaToken String
  | NoOp

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChangeRank choice rank ->
      let
        oldPoll = model.poll
        ( newOrdered, newUnordered ) = changeRank rank choice oldPoll.orderedChoices oldPoll.unorderedChoices
        newPoll = { oldPoll | orderedChoices = newOrdered, unorderedChoices = newUnordered }
        newFadeStyle =
          Animation.interrupt
            [ Animation.set [ Animation.opacity 0 ]
            , Animation.to [ Animation.opacity 1 ]
            ]
            model.fadeStyle

        focus =
          if rank == "--" then
            "unordered-" ++ ( String.fromInt <| List.length newUnordered - 1)
          else
            "ordered-" ++ rank
      in
      ( { model | poll = newPoll, showError = False, fadeStyle = newFadeStyle, fadeChoice = choice }
      , Task.attempt ( \_ -> NoOp ) ( Dom.focus focus )
      )

    SubmitVoteRequest -> ( model, submitVoteRequest model)

    SubmitVoteResponse result ->
      case result of
        Ok _ -> ( model, Navigation.pushUrl model.key ( "/poll/" ++ model.pollId ) )

        Err error ->
          let
            newError =
              case error of
                Http.Detailed.BadStatus _ body ->
                  body
                _ ->
                  "Unable to submit vote. The website may be down for maintenace. Please try again later."
          in ( { model | showError = True, error = newError }, Cmd.none )

    Animate animate -> ( { model | fadeStyle = Animation.update animate model.fadeStyle }, Cmd.none )

    RecaptchaToken recaptchaToken -> ( { model | recaptchaToken = recaptchaToken }, Cmd.none )

    NoOp -> ( model, Cmd.none )

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

submitVoteRequest : Model -> Cmd Msg
submitVoteRequest model =
  Http.post
    { url = model.apiAddress ++ "/vote/"
    , body = Http.jsonBody <| submitVoteJson model
    , expect = Http.Detailed.expectString SubmitVoteResponse
    }

submitVoteJson : Model -> Encode.Value
submitVoteJson model =
  let choices = Dict.foldl buildSubmissionChoices Dict.empty model.poll.orderedChoices
  in
  Encode.object
    [ ( "poll_id", Encode.string model.pollId )
    , ( "choices", Encode.dict identity Encode.int choices )
    , ( "recaptcha_token", Encode.string model.recaptchaToken )
    ]

buildSubmissionChoices : Int -> String -> Dict.Dict String Int -> Dict.Dict String Int
buildSubmissionChoices rank choice choices =
  Dict.insert choice rank choices



-- VIEW
view : Model -> Html Msg
view model =
  case model.loadingState of
    Error -> Page.Error.view

    Loaded ->
      let
        maxOrdered = Dict.size model.poll.orderedChoices
        maxUnordered = List.length model.poll.unorderedChoices
        maxRank = maxOrdered + maxUnordered
        hasOrderedChoices = not <| Dict.isEmpty model.poll.orderedChoices
      in
      div []
        [ div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8" ] [ text "--" ]
            , p [ class "fv-text w-full" ] [ text "Submit a new vote by selecting a rank to the left of each choice. Note that smaller ranks get more preference and not all choices need to have a rank." ]
            , div [ class "w-8" ] []
            ]

        , div [ class "flex justify-between" ]
            [ h1 [ class "fv-code" ] [ text "vote" ]
            , div [ class "fv-code" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8" ] [ text "{" ]
            , h2 [ class "fv-header" ] [ text "Question" ]
            , div [ class "fv-code w-8 text-right" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8"] [ text "\"" ]
            , div [ class "flex justify-center w-full"]
                [ div [ class "fv-text text-blue-100 text-left" ] [ text model.poll.title ] ]
            , div [class "fv-code w-8 text-right" ] [ text "\"" ]
            ]

        , div [ class "fv-code" ] [ text "," ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8" ] []
            , h2 [ class "fv-header" ] [ text "Created" ]
            , div [ class "fv-code w-8 text-right" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8"] [ text "\"" ]
            , div [ class "flex justify-center w-full"]
                [ div [ class "fv-text text-blue-100 text-left" ] [ text model.poll.created ] ]
            , div [class "fv-code w-8 text-right" ] [ text "\"" ]
            ]

        , div [ class "fv-code" ] [ text "," ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "fv-header" ] [ text "Ranks" ]
            , div [ class "fv-code w-8 text-right" ] [ text "=" ]
            ]

        , div [] ( List.indexedMap ( renderOrdered maxRank maxOrdered model ) <| Dict.toList model.poll.orderedChoices )

        , div [ class "fv-break my-2" ] [ text "--" ]

        , div [] ( List.indexedMap ( renderUnordered maxRank maxUnordered hasOrderedChoices model ) <| model.poll.unorderedChoices )

        , if model.poll.useRecaptcha then
            div []
              [ div [ class "fv-code" ] [ text "," ]
              , div [ class "flex justify-between items-center" ]
                  [ div [ class "w-8" ] []
                  , h2 [ class "fv-header" ] [ text "reCAPTCHA" ]
                  , div [ class "fv-code w-8 text-right" ] [ text "=" ]
                  ]
              , div [ class "w-full flex justify-center"]
                  [ let
                      sitekey =
                        if model.env == "production" then "6Ld44ukUAAAAAGaOzaluZITl3zQE-6fbgZh2O2PC"
                        else "6LeskukUAAAAACVQNLgOef9dSxPau59T04w4r9CA"
                    in
                    div
                      [ attribute "data-sitekey" sitekey
                      , class "g-recaptcha"
                      , id "recaptcha"
                      ] []
                  ]
              , div [ class "fv-code pb-2" ] [ text "}" ]
              ]

          else
            div [ class "fv-code pb-2" ] [ text "]}" ]

        , div [ class "flex justify-between pb-1" ]
            [ div [ class "w-8" ] []
            , button
                [ class "fv-btn"
                , onClick SubmitVoteRequest
                ]
                [ text "Submit Vote" ]
            , div [ class "w-8" ] []
            ]

        , div [ class "flex justify-between" ]
            [ div [ class "fv-code w-8" ] [ errorComment model.error ]
            , div [ class "w-full fv-text fv-text-error" ] [ errorText model.error ]
            , div [ class "w-8" ] []
            ]

        , div [ class "fv-break" ] [ text "--" ]

        , div [ class "flex justify-between items-center mb-2" ]
            [ div [ class "fv-code w-8" ] [ text "--" ]
            , p [ class "fv-text w-full" ] [ text "Go to the results page by clicking the button." ]
            , div [ class "w-8" ] []
            ]

        , div [ class "flex justify-between" ]
            [ div [ class "w-8" ] []
            , a
              [ class "fv-btn fv-btn-blank mb-2"
              , href <| "/poll/" ++ model.pollId
              ]
              [ text "View Results" ]
            , div [ class "w-8" ] []
            ]

        , Shared.renderShareLinks
            ( "https://functionalvote.maxrchung.com/vote/" ++ model.pollId )
            "Share this voting page by copying the links or clicking the buttons on the right."
            model.poll.title
            "Vote in my poll: "
        ]

renderOrdered : Int -> Int -> Model -> Int -> ( Int, String ) -> Html Msg
renderOrdered maxRank maxIndex model index ( rank, choice ) =
  renderChoice maxRank maxIndex False model index ( String.fromInt rank, choice )

renderUnordered : Int -> Int -> Bool -> Model -> Int -> String -> Html Msg
renderUnordered maxRank maxIndex hasOrderedChoices model index choice  =
  renderChoice maxRank maxIndex hasOrderedChoices model index ( "--", choice )

renderChoice : Int -> Int -> Bool -> Model -> Int -> ( String, String ) -> Html Msg
renderChoice maxRank maxIndex hasOrderedChoices model index ( rank, choice ) =
  let
    selectIndex =
      if rank == "--" then
        "unordered-" ++ String.fromInt index
      else
        "ordered-" ++ rank
  in
  div
    [ class "flex justify-between items-center" ]
    [ div [ class "fv-code w-8"]
        [ unorderedCommaText hasOrderedChoices index
        , text "("
        ]

    , div
        [ class "flex items-center w-full p-2"
        , textColorClass index
        , borderClass index maxIndex
        ]
        [ select
            [ class "fv-input fv-input-select w-auto"
            , errorClass model.showError
            , id selectIndex
            , value rank
            , onInput ( ChangeRank choice )
            ]
            ( List.concat
              [ renderOptions maxRank rank
              , [ option
                  [ value "--"
                  , selected ( rank == "--" )
                  ]
                  [ text "--" ]
                ]
              ]
            )

        , div [ class "fv-code w-8 text-center" ] [ text ",\"" ]

        , div
            ( List.concat
                [ if model.fadeChoice == choice then
                    Animation.render model.fadeStyle
                  else
                    []
                , [ class "fv-text text-blue-100 w-full" ]
                ]
            )
            [ text choice ]
        ]

    , div [class "fv-code w-8 text-right" ] [ text "\")" ]
    ]

renderOptions : Int -> String -> List ( Html Msg )
renderOptions maxRank selectedRank =
  List.map ( renderOption selectedRank ) <| List.range 1 maxRank

renderOption : String -> Int -> Html Msg
renderOption selectedRank rank  =
  case String.toInt selectedRank of
     Nothing -> option [ value <| String.fromInt rank ] [ text <| rankValue rank ]

     Just selectedRankInt ->
      option
        [ value <| String.fromInt rank
        , selected ( selectedRankInt == rank )
        ]
        [ text <| rankValue rank]

unorderedCommaText : Bool -> Int -> Html a
unorderedCommaText hasOrderedChoices index =
  if hasOrderedChoices || index > 0 then
    text ","
  else
    text "["

textColorClass : Int -> Attribute a
textColorClass index =
  if modBy 2 index == 0 then
    class "bg-blue-800"
  else
    class "bg-blue-900"

borderClass : Int -> Int -> Attribute a
borderClass index maxIndex =
  if maxIndex == 1 then
    class "rounded-sm shadow-lg"
  else if index == 0 then
    class "rounded-t-sm"
  else if index == maxIndex - 1 then
    class "rounded-b-sm shadow-lg"
  else
    class ""

errorClass : Bool -> Attribute a
errorClass showError =
  if showError then
    class "fv-input-error"
  else
    class ""

errorComment : String -> Html a
errorComment error =
  if String.isEmpty error then
    text ""
  else
    text "--"

errorText : String -> Html a
errorText error =
  if String.isEmpty error then
    text ""
  else
    text error

rankValue : Int -> String
rankValue rank =
  String.fromInt rank ++
    case modBy 100 rank of
      11 -> "th"
      12 -> "th"
      13 -> "th"
      _ ->
        case modBy 10 rank of
          1 -> "st"
          2 -> "nd"
          3 -> "rd"
          _ -> "th"