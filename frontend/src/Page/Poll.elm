module Page.Poll exposing ( .. )

import Axis
import Browser.Events
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Interpolation
import List.Extra
import Page.Error
import Scale exposing ( BandScale, ContinuousScale, defaultBandConfig )
import Shared
import Time exposing ( Posix, Zone )
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
  , loadingState : LoadingState
  , transition : Transition.Transition ( List ( String, Float ) )
  }

type alias Poll =
  { title : String
  , winner : String
  , tallies : List ( List ( String, Float ) )
  , created : String
  }

type LoadingState
  = Loaded
  | Error

init : Navigation.Key -> String -> String -> String -> List ( List ( String, Float ) ) -> String -> Posix -> Zone -> LoadingState -> Model
init key apiAddress title winner tallies pollId created timezone loadingState =
  let
    removedEmpty = removeEmpty tallies
    removedDuplicate = removeDuplicate removedEmpty
    humanTimeString = Shared.toHumanTimeString created timezone
    newPoll = Poll title winner ( reorderTallies removedDuplicate ) humanTimeString
    lastRound =
      case List.Extra.last newPoll.tallies of
          Nothing -> []
          Just last -> last
    newXScaleMax =
      case List.head lastRound of
        Nothing -> 0
        Just head -> Tuple.second head
    newStep = List.length newPoll.tallies - 1
    newTransition = updateTransition ( Transition.constant [] ) newStep newPoll.tallies
  in
  { key = key
  , pollId = pollId
  , poll = newPoll
  , apiAddress = apiAddress
  , step = newStep
  , xScaleMax = newXScaleMax
  , loadingState = loadingState
  , transition =  newTransition
  }



-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
    if Transition.isComplete model.transition then
        Sub.none
    else
        Browser.Events.onAnimationFrameDelta ( round >> Tick )



-- UPDATE
type Msg
  = DecrementStep
  | IncrementStep
  | ChangeStep String
  | Tick Int

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    DecrementStep ->
      let
        newStep =
          if model.step == 0 then
            model.step
          else
            model.step - 1
        newTransition =
          if newStep == model.step then
            model.transition
          else
            updateTransition model.transition newStep model.poll.tallies
      in ( { model | step = newStep, transition = newTransition }, Cmd.none )

    IncrementStep ->
      let
        newStep =
          if model.step == List.length model.poll.tallies - 1 then
            model.step
          else
            model.step + 1
        newTransition =
          if newStep == model.step then
            model.transition
          else
            updateTransition model.transition newStep model.poll.tallies
      in ( { model | step = newStep, transition = newTransition }, Cmd.none )

    ChangeStep stepString ->
      let
        newStep =
          case String.toInt stepString of
            Nothing ->
              0
            Just stepInt ->
              stepInt
        newTransition = updateTransition model.transition newStep model.poll.tallies
      in ( { model | step = newStep, transition = newTransition }, Cmd.none )

    Tick tick ->
      let newTransition = Transition.step tick model.transition
      in ( { model | transition = newTransition } , Cmd.none )

updateTransition : Transition.Transition ( List ( String, Float ) ) -> Int -> List ( List ( String, Float ) ) -> Transition.Transition ( List ( String, Float ) )
updateTransition oldTransition newStep tallies =
  let
    currValue = Transition.value oldTransition
    newRound =
      case List.Extra.getAt newStep tallies of
         Nothing -> []
         Just getAt -> getAt
  in Transition.for 500 ( interpolateRound currValue newRound )

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

removeEmpty : List ( List ( String, Float ) ) -> List ( List ( String, Float ) )
removeEmpty tallies =
  List.map removeEmptyEntries tallies

removeEmptyEntries : List ( String, Float ) -> List ( String, Float )
removeEmptyEntries round =
  List.filter (\( _, tallies ) -> tallies > 0) round

removeDuplicate : List ( List ( String, Float ) ) -> List ( List ( String, Float ) )
removeDuplicate tallies =
  List.foldr removeDuplicateFold [] tallies

removeDuplicateFold : List ( String, Float ) -> List ( List ( String, Float ) ) -> List ( List ( String, Float ) )
removeDuplicateFold round list =
  case List.head list of
    Nothing -> round :: list
    Just head ->
      if List.length round == List.length head then
        list
      else
        round :: list

reorderTallies : List ( List ( String, Float ) ) -> List ( List ( String, Float ) )
reorderTallies tallies =
  List.map reorderRound tallies

reorderRound : List ( String, Float ) -> List ( String, Float )
reorderRound round =
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
  case model.loadingState of
    Error -> Page.Error.view

    Loaded ->
      div []
        [ div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8" ] [ text "--" ]
            , p [ class "fv-text w-full" ] [ text "View the poll results and see how the winner is determined. In case of ties, a winner is randomly decided." ]
            , div [ class "w-8" ] []
            ]

        , div [ class "flex justify-between" ]
            [ h1 [ class "fv-code" ] [ text "results" ]
            , div [ class "fv-code" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8" ] [ text "{" ]
            , h2 [ class "fv-header" ] [ text "Question" ]
            , div [ class "fv-code w-8 text-right" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8"] [ text "\"" ]
            , div
              [ class "flex justify-center w-full"]
              [ div
                [ class "fv-text text-blue-100 text-left" ]
                [ text model.poll.title ]
              ]
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
            , div
              [ class "flex justify-center w-full"]
              [ div
                [ class "fv-text text-blue-100 text-left" ]
                [ text model.poll.created ]
              ]
            , div [class "fv-code w-8 text-right" ] [ text "\"" ]
            ]

        , div [ class "fv-code" ] [ text "," ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "fv-header" ] [ text "Winner" ]
            , div [ class "fv-code w-8 text-right" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ div [ class "fv-code w-8"] [ text "\"" ]
            , div [ class "flex justify-center w-full"]
              [ div
                [ class "fv-text text-blue-100 text-left" ]
                [ text model.poll.winner ]
              ]
            , div [class "fv-code w-8 text-right" ] [ text "\"" ]
            ]

        , renderResults model.step model.xScaleMax model.poll.tallies <| Transition.value model.transition

        , div [ class "fv-code" ] [ text "}" ]

        , div [ class "fv-break" ] [ text "--" ]

        , div [ class "flex justify-between items-center mb-2" ]
            [ div [ class "fv-code w-8" ] [ text "--" ]
            , p [ class "fv-text w-full" ] [ text "View the vote submission page to submit another vote." ]
            , div [ class "w-8" ] []
            ]

        , div [ class "flex justify-between" ]
            [ div [ class "w-8" ] []
            , a
              [ class "fv-btn fv-btn-blank mb-2"
              , href <| "/vote/" ++ model.pollId
              ]
              [ text "Submit Vote" ]
            , div [ class "w-8" ] []
            ]

        , Shared.renderShareLinks
            ( "https://functionalvote.com/poll/" ++ model.pollId )
            "Share this poll results page by copying the link or sharing through social media."
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
        55 + 2 * 6 + 30 * List.length round
  in ResultsConfig 375 ( toFloat height ) 30 xScaleMax

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
  let choiceText = String.fromInt ( round votes ) ++ " - " ++ choice
  in
  Svg.g []
    [ Svg.rect
        [ SvgAttributes.class [ "text-blue-900 fill-current" ]
        , SvgInPx.y <| Scale.convert scale choice
        , SvgInPx.width <| Scale.convert ( xScale config ) votes
        , SvgInPx.height <| Scale.bandwidth scale
        ] []
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
        , div [ class "flex justify-between items-center" ]
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
    div [ class "flex justify-between items-center" ]
      [ div [ class "w-8" ] []
      , div [ class "flex justify-between items-center mt-2 w-full" ]
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
            ] []

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
  let
    reordered = reorderRound round
  in
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
        [ yAxis config reordered ]
    , Svg.g [ SvgAttributes.transform [ SvgTypes.Translate config.padding config.padding ] ] <|
        List.map ( row config <| yScale config reordered ) reordered
    ]