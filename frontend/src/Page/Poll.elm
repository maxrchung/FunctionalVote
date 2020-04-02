module Page.Poll exposing ( .. )

import Axis
import Browser.Events
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Interpolation
import Json.Decode as Decode
import List.Extra
import Scale exposing ( BandScale, ContinuousScale, defaultBandConfig )
import Shared
import Transition
import TypedSvg as Svg
import TypedSvg.Attributes as SvgAttributes
import TypedSvg.Attributes.InPx as SvgInPx
import TypedSvg.Core as SvgCore
import TypedSvg.Types as SvgTypes



-- MODEL
type alias Model = 
  { key : Navigation.Key
  , pollId : String
  , poll : Poll
  , apiAddress : String
  , step : Int
  , xScaleMax : Float
  , isLoading : Bool
  , transition : Transition.Transition ( List ( String, Float ) )
  }

type alias Poll =
  { title : String
  , winner : String
  , tallies : List ( List ( String, Float ) )
  }

init : Navigation.Key -> String -> String -> ( Model, Cmd Msg )
init key pollId apiAddress = 
  let 
    model = 
      { key = key
      , pollId = pollId
      , poll = Poll "" "" []
      , apiAddress = apiAddress
      , step = 0
      , xScaleMax = 0
      , isLoading = True
      , transition = Transition.constant []
      }
  in ( model, getPollRequest model )



-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
    if Transition.isComplete model.transition then
        Sub.none
    else
        Browser.Events.onAnimationFrameDelta ( round >> Tick )



-- UPDATE
type Msg 
  = GetPollResponse ( Result Http.Error Poll )
  | DecrementStep
  | IncrementStep
  | ChangeStep String
  | Tick Int

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok response ->
          let
            newPoll = { response | tallies = reorderTallies response.tallies}
            lastRound = 
              case List.Extra.last newPoll.tallies of
                  Nothing -> []
                  Just last -> last
            newXScaleMax = 
              case List.head lastRound of
                Nothing -> 0
                Just head -> Tuple.second head
          in
          ( { model 
            | poll = newPoll
            , step = List.length newPoll.tallies - 1 
            , xScaleMax = newXScaleMax
            , isLoading = False
            }
          , Cmd.none 
          )

        Err _ ->
          ( model, Navigation.pushUrl model.key "/error" )

    DecrementStep ->
      let
        newStep =
          if model.step == 0 then
            model.step
          else
            model.step - 1
        newTransition = updateTransition newStep model
      in ( { model | step = newStep, transition = newTransition }, Cmd.none )

    IncrementStep ->
      let
        newStep =
          if model.step == List.length model.poll.tallies - 1 then
            model.step
          else
            model.step + 1
        newTransition = updateTransition newStep model
      in ( { model | step = newStep, transition = newTransition }, Cmd.none )

    ChangeStep stepString ->
      let
        newStep =
          case String.toInt stepString of
            Nothing ->
              0
            Just stepInt ->
              stepInt
        newTransition = updateTransition newStep model
      in ( { model | step = newStep, transition = newTransition }, Cmd.none )

    Tick t ->
      let newTransition = Transition.step t model.transition
      in ( { model | transition = newTransition } , Cmd.none )

updateTransition : Int -> Model -> Transition.Transition ( List ( String, Float ) )
updateTransition newStep model =
  let 
    currValue = Transition.value model.transition
    newRound = 
      case List.Extra.getAt newStep model.poll.tallies of
         Nothing -> []
         Just getAt -> getAt
  in Transition.for 600 ( interpolateRound currValue newRound )

interpolateRound : List ( String, Float ) -> List ( String, Float ) -> Interpolation.Interpolator ( List ( String, Float ) )
interpolateRound from to =
  Interpolation.list
    { add = \( toChoice, toTallies ) -> interpolateEntries ( toChoice, 0 ) ( toChoice, toTallies )
    , remove = \( fromChoice, fromTallies ) -> interpolateEntries ( fromChoice, fromTallies ) ( fromChoice, 0 )
    , change = interpolateEntries
    , id = \( choice, _ ) -> choice
    , combine = Interpolation.combineParallel
    }
    from
    to

interpolateEntries : ( String, Float ) -> ( String, Float ) -> Interpolation.Interpolator ( String, Float )
interpolateEntries ( _, fromTallies ) ( toChoice, toTallies ) =
  Interpolation.map ( Tuple.pair toChoice ) ( Interpolation.float fromTallies toTallies )


getPollRequest : Model -> Cmd Msg
getPollRequest model =
  Http.get
    { url = model.apiAddress ++ "/poll/" ++ model.pollId
    , expect = Http.expectJson GetPollResponse getPollDecoder
    }

getPollDecoder : Decode.Decoder Poll
getPollDecoder =
  Decode.map3 Poll
    ( Decode.at ["data", "title" ] Decode.string )
    ( Decode.at ["data", "winner"] Decode.string )
    ( Decode.at ["data", "tallies"] <| Decode.list <| Decode.keyValuePairs Decode.float )

reorderTallies : List ( List ( String, Float ) ) -> List ( List ( String, Float ) )
reorderTallies tallies =
  List.map reorderRounds tallies

reorderRounds : List ( String, Float ) -> List ( String, Float )
reorderRounds round =
  List.sortWith compareEntries round

compareEntries : ( String, Float ) -> ( String, Float ) -> Order
compareEntries ( _, a ) ( _, b ) =
  case compare a b of
      LT -> GT
      EQ -> EQ
      GT -> LT



-- VIEW
view : Model -> Html Msg
view model =
  if model.isLoading then
    div [] []
  else
    div 
      [] 
      [ div 
          [ class "fv-text" ]
          [ text "-- View the poll results and see how results were calculated. In case of ties, a winner is randomly decided." ]

      , div
          [ class "flex justify-between" ]
          [ h1 [ class "fv-code" ] [ text "results" ]
          , div [ class "fv-code" ] [ text "={" ]
          ]

      , div
          [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] []
          , h2 [ class "fv-header" ] [ text "Question" ]
          , div [ class "fv-code w-8 text-right" ] [ text "=" ]
          ]

      , div
          [ class "flex justify-between items-center" ]
          [ div [ class "fv-code w-8"] [ text "\"" ]
          , div
            [ class "flex justify-center w-full"]
            [ h1
              [ class "fv-text text-blue-100 text-left" ]
              [ text model.poll.title ]
            ]
          , div [class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "fv-code" ] [ text "," ]

      , div
          [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] []
          , h2 [ class "fv-header" ] [ text "Winner" ]
          , div [ class "fv-code w-8 text-right" ] [ text "=" ]
          ]

      , div
          [ class "flex justify-between items-center" ]
          [ div [ class "fv-code w-8"] [ text "\"" ]
          , div 
            [ class "flex justify-center w-full"]
            [ h1
              [ class "fv-text text-blue-100 text-left" ] 
              [ text model.poll.winner ]
            ]
          , div [class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , renderResults model.step model.xScaleMax model.poll.tallies <| Transition.value model.transition

      , div [ class "fv-code" ] [ text "}" ]

      , div
          [ class "fv-break" ]
          [ text "--" ]
      
      , div
          [ class "fv-text mb-2" ]
          [ text "-- Submit a new vote into the poll." ]
        
      , div 
          [ class "flex justify-between" ]
          [ div [ class "w-8" ] [ text "" ]
          , a
            [ class "fv-btn fv-btn-blank mb-2"
            , href <| "/vote/" ++ model.pollId
            ]
            [ text "Submit Vote" ]
          , div [ class "w-8 text-right" ] [ text "" ]
          ]

      , Shared.renderShareLinks
          ( "https://functionalvote.com/poll/" ++ model.pollId )
          "-- Share the poll results page." 
          model.poll.title
          "View my poll results: "
      ]

type alias ResultsConfig = 
  { width: Float
  , height: Float
  , padding: Float
  , xScaleMax: Float
  }

initResults : List ( String, Float ) -> Float -> ResultsConfig
initResults round xScaleMax =
  let
    height = 
        100 + 30 * List.length round - 1
  in
  ResultsConfig 375 ( toFloat height ) 30 xScaleMax

xScale : ResultsConfig -> ContinuousScale Float
xScale config =
  Scale.linear ( 0, config.width - 2 * config.padding ) ( 0, config.xScaleMax )

yScale : ResultsConfig -> List ( String, Float ) -> BandScale String
yScale config round =
  List.map Tuple.first round
    |> Scale.band { defaultBandConfig | paddingInner = 0.2, paddingOuter = 0.2 } ( 0, config.height - 2 * config.padding )

xAxis : ResultsConfig -> SvgCore.Svg a
xAxis config =
  Axis.top [ Axis.tickCount 8 ] <| xScale config

yAxis : ResultsConfig -> List ( String, Float ) -> SvgCore.Svg a
yAxis config round =
  -- List.map so that empty string is shown as ticks
  Axis.left [] <| Scale.toRenderable identity <| yScale config round

row : ResultsConfig -> BandScale String -> ( String, Float ) -> SvgCore.Svg a
row config scale ( choice, votes ) =
  let choiceText = String.fromFloat votes ++ " - " ++ choice
  in
  Svg.g
    []
    [ Svg.rect
        [ SvgAttributes.class [ "text-blue-900 fill-current" ] 
        , SvgInPx.y <| Scale.convert scale choice
        , SvgInPx.width <| Scale.convert ( xScale config ) votes
        , SvgInPx.height <| Scale.bandwidth scale
        ]
        []
    , Svg.text_
          [ SvgAttributes.class 
              [ choiceTextColor votes config.xScaleMax
              , "fill-current text-sm" ]
          , SvgInPx.x <| config.padding / 4
          , SvgInPx.y <| Scale.convert scale choice + ( Scale.bandwidth scale / 2 )
          , SvgAttributes.textAnchor SvgTypes.AnchorStart
          , SvgAttributes.dominantBaseline SvgTypes.DominantBaselineMiddle
          ]
          [ SvgCore.text <| truncateChoice choiceText ]
    ]
    
choiceTextColor : Float -> Float -> String
choiceTextColor votes xScaleMax =
  if votes == xScaleMax then
    "text-blue-100"
  else
    "text-blue-500"

truncateChoice : String -> String
truncateChoice choice =
  if String.length choice > 27 then
    String.slice 0 27 choice  ++ "..."
  else
    choice

renderResults : Int -> Float -> List ( List ( String, Float ) ) -> List ( String, Float ) -> Html Msg
renderResults step xScaleMax tallies transition =
  div []
    ( if List.isEmpty tallies then
        []
      else
        [ div [ class "fv-code" ] [ text "," ]
        , div 
            [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "fv-header" ] [ text "Results" ]
            , div [ class "fv-code w-8 text-right" ] [ text "=" ]
            ]

        , renderSlider step tallies
        , renderChart ( initResults transition xScaleMax ) transition
        ]
    )

renderSlider : Int -> List ( List ( String, Float ) ) -> Html Msg
renderSlider step tallies =
  -- Only show slider if there's at least 2 elements
  if List.length ( List.take 2 tallies ) < 2 then
    div [] []
  else
    div 
      [ class "flex justify-between items-center" ]
      [ div [ class "w-8" ] []
      , div 
        [ class "flex justify-between items-center mt-2 w-full" ]
        [ button 
          [ class "fv-nav-btn fv-nav-btn-blue" 
          , onClick DecrementStep
          ]
          [ Shared.renderIcon FeatherIcons.arrowLeft ]

        , input 
            [ class "fv-slider w-full mx-2"
            , type_ "range"
            , onInput ChangeStep
            , Html.Attributes.max <| String.fromInt <| List.length tallies - 1
            , value <| String.fromInt step
            ]
            []

        , button 
            [ class "fv-nav-btn fv-nav-btn-blue" 
            , onClick IncrementStep
            ]
            [ Shared.renderIcon FeatherIcons.arrowRight ]
        ]
      , div [ class "w-8" ] []
      ]

renderChart : ResultsConfig -> List ( String, Float ) -> SvgCore.Svg a
renderChart config round =
  Svg.svg
    [ SvgAttributes.class [ "fv-results" ]
    , SvgAttributes.viewBox 0 0 config.width ( config.height - config.padding / 2 )
    ]
    [ Svg.g [ SvgAttributes.transform [ SvgTypes.Translate ( config.padding - 1 ) config.padding ] ]
        [ xAxis config ]
    , Svg.g
        [ SvgAttributes.transform [ SvgTypes.Translate ( config.padding - 1 ) config.padding ]
        , SvgAttributes.class [ "y-axis" ]
        ]
        [ yAxis config round ]
    , Svg.g [ SvgAttributes.transform [ SvgTypes.Translate config.padding config.padding ] ] <|
        List.map ( row config <| yScale config round ) round
    ]