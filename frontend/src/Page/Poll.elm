module Page.Poll exposing ( .. )

import Axis
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Json.Decode as Decode
import List.Extra
import Scale exposing ( BandScale, ContinuousScale, defaultBandConfig )
import TypedSvg as Svg
import TypedSvg.Attributes as SvgAttributes
import TypedSvg.Attributes.InPx as SvgInPx
import TypedSvg.Core as SvgCore
import TypedSvg.Types as SvgTypes



-- MODEL
type alias Model = 
  { pollId: String
  , poll: Poll
  , apiAddress: String
  , step: Int
  , xScaleMax: Int
  }

type alias Poll =
  { title: String
  , winner: String
  , timeline: List ( List ( Int, String ) )
  }

init : String -> String -> ( Model, Cmd Msg )
init pollId apiAddress = 
  let model = Model pollId ( Poll "" "" [] ) apiAddress 0 0
  in ( model, getPollRequest model )



-- UPDATE
type Msg 
  = GetPollResponse ( Result Http.Error Poll )
  | GoToVote
  | DecrementStep
  | IncrementStep
  | ChangeStep String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok newPoll ->
          let
              lastRound = 
                case List.Extra.last newPoll.timeline of
                   Nothing -> []
                   Just last -> last
              newXScaleMax = 
                case List.head lastRound of
                  Nothing -> 0
                  Just head -> Tuple.first head
          in
          ( { model 
            | poll = newPoll
            , step = List.length newPoll.timeline - 1 
            , xScaleMax = newXScaleMax
            }
          , Cmd.none 
          )

        Err _ ->
          ( model, Cmd.none )

    GoToVote ->
      ( model, Navigation.load ( "/vote/" ++ model.pollId ) )

    DecrementStep ->
      let
          newStep =
            if model.step == 0 then
              model.step
            else
              model.step - 1
      in
      ( { model | step = newStep }, Cmd.none )

    IncrementStep ->
      let
          newStep =
            if model.step == List.length model.poll.timeline - 1 then
              model.step
            else
              model.step + 1
      in
      ( { model | step = newStep }, Cmd.none )

    ChangeStep stepString ->
      let
        newStep =
          case String.toInt stepString of
            Nothing ->
              0
            Just stepInt ->
              stepInt
      in
      ( { model | step = newStep }, Cmd.none )

getPollRequest : Model -> Cmd Msg
getPollRequest model =
  Http.get
    { url = model.apiAddress ++ "/poll/" ++ model.pollId
    , expect = Http.expectJson GetPollResponse getPollDecoder
    }

getPollDecoder : Decode.Decoder Poll
getPollDecoder =
  Decode.map2 pollSample
    ( Decode.at ["data", "title" ] Decode.string )
    ( Decode.at ["data", "winner"] Decode.string )

pollSample : String -> String -> Poll
pollSample title winner =
  Poll 
    title
    winner 
    [
    --   [ ( 12, "highest choice" )
    --   , ( 10, "higher choice" )
    --   , ( 8, "lower choice" )
    --   , ( 3, "lowest choice" )
    --   ]
    -- , [ ( 12, "highest choice" )
    --   , ( 12, "higher choice" )
    --   , ( 9, "lower choice" )
    --   ]
    -- , [ ( 17, "higher choice" )
    --   , ( 16, "highest choice" )
    --   ]
    ]



-- VIEW
view : Model -> Html Msg
view model =
  div 
    [] 
    [ div 
        [ class "fv-main-text" ]
        [ text "-- View the poll results and navigate the timeline to see how results were calculated." ]

    , div 
        [ class "flex justify-between" ]
        [ h1 [ class "fv-main-code" ] [ text "results" ]
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
            [ class "fv-main-text text-blue-100 text-left" ] 
            [ text model.poll.title ]
          ]
        , div [class "fv-main-code w-8 text-right" ] [ text "\"" ]
        ]

    , div [ class "fv-main-code" ] [ text "," ]

    , div 
        [ class "flex justify-between items-center" ]
        [ div [ class "w-8" ] []
        , h2 [ class "fv-main-header" ] [ text "Winner" ]
        , div [ class "fv-main-code w-8 text-right" ] [ text "=" ]
        ]

    , div 
        [ class "flex justify-between items-center" ]
        [ div [ class "fv-main-code w-8"] [ text "\"" ]
        , div 
          [ class "flex justify-center w-full"]
          [ h1 
            [ class "fv-main-text text-blue-100 text-left" ] 
            [ text model.poll.winner ]
          ]
        , div [class "fv-main-code w-8 text-right" ] [ text "\"" ]
        ]

    , renderTimeline model

    , div [ class "fv-main-code" ] [ text "}" ]

    , div
        [ class "fv-main-code text-center w-full my-3" ] 
        [ text "--" ]
    
    , div
        [ class "fv-main-text mb-2" ]
        [ text "-- Submit a new vote into the poll." ]
      
    , div 
        [ class "flex justify-between" ]
        [ div [ class "w-8" ] [ text "" ]
        , button 
          [ class "fv-main-btn mb-2 bg-gray-900 text-orange-500 border-2 border-orange-500"
          , onClick GoToVote
          ] 
          [ text "Submit Vote" ]
        , div [ class "w-8 text-right" ] [ text "" ]
        ]
    ]

type alias TimelineConfig = 
  { width: Float
  , height: Float
  , padding: Float
  , xScaleMax: Int
  }

initTimeline : List ( Int, String ) -> Int -> TimelineConfig
initTimeline round xScaleMax =
  let
    height = 
        100 + 30 * List.length round - 1
  in
  TimelineConfig 375 ( toFloat height ) 30 xScaleMax

xScale : TimelineConfig -> ContinuousScale Float
xScale config =
  Scale.linear ( 0, config.width - 2 * config.padding ) ( 0, toFloat config.xScaleMax )

yScale : TimelineConfig -> List ( Int, String ) -> BandScale String
yScale config round =
  List.map Tuple.second round
    |> Scale.band { defaultBandConfig | paddingInner = 0.2, paddingOuter = 0.2 } ( 0, config.height - 2 * config.padding )

xAxis : TimelineConfig -> SvgCore.Svg msg
xAxis config =
  Axis.top [ Axis.tickCount 8 ] <| xScale config

yAxis : TimelineConfig -> List ( Int, String ) -> SvgCore.Svg msg
yAxis config round =
  -- List.map so that empty string is shown as ticks
  Axis.left [] <| Scale.toRenderable identity <| yScale config round

row : TimelineConfig -> BandScale String -> ( Int, String ) -> SvgCore.Svg msg
row config scale ( votes, choice ) =
  Svg.g
    []
    [ Svg.rect
        [ SvgAttributes.class [ "text-blue-900 fill-current" ] 
        , SvgInPx.y <| Scale.convert scale choice
        , SvgInPx.width <| Scale.convert ( xScale config ) <| toFloat votes
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
          [ SvgCore.text <| truncateChoice choice ]
    ]
    
choiceTextColor : Int -> Int -> String
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

renderTimeline : Model -> Html Msg
renderTimeline model =
  let
      round = 
        case List.Extra.getAt model.step model.poll.timeline of
          Nothing -> []
          Just getAt -> getAt
  in
    div []
      ( if List.isEmpty model.poll.timeline then
          []
        else
          [ div [ class "fv-main-code" ] [ text "," ]
          , div 
              [ class "flex justify-between items-center" ]
              [ div [ class "w-8" ] []
              , h2 [ class "fv-main-header" ] [ text "Timeline" ]
              , div [ class "fv-main-code w-8 text-right" ] [ text "=" ]
              ]

          , div 
              [ class "flex justify-between items-center" ]
              [ div [ class "w-8" ] []
              , div 
                [ class "flex justify-between items-center mt-2 w-full" ]
                [ button 
                  [ class "fv-nav-btn" 
                  , onClick DecrementStep
                  ] 
                  [ FeatherIcons.arrowLeft
                    |> FeatherIcons.withSize 22
                    |> FeatherIcons.withStrokeWidth 2
                    |> FeatherIcons.toHtml [] ]

                , input 
                    [ class "flex-grow mx-2 fv-slider"
                    , type_ "range"
                    , onInput ChangeStep
                    , Html.Attributes.max <| String.fromInt <| List.length model.poll.timeline - 1
                    , value <| String.fromInt model.step
                    ]
                    []

                , button 
                  [ class "fv-nav-btn" 
                  , onClick IncrementStep
                  ] 
                  [ FeatherIcons.arrowRight
                    |> FeatherIcons.withSize 22
                    |> FeatherIcons.withStrokeWidth 2
                    |> FeatherIcons.toHtml [] ]
                ]
              , div [ class "w-8" ] []
              ]
          , renderChart ( initTimeline round model.xScaleMax ) round
          ]
      )

renderChart : TimelineConfig -> List ( Int, String ) -> SvgCore.Svg msg
renderChart config round =
  Svg.svg
    [ SvgAttributes.class [ "fv-timeline" ]
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