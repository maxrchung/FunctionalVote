module Page.Poll exposing ( .. )

import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Json.Decode as Decode

import Axis
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
  }

type alias Poll =
  { title: String
  , winner: String
  , timeline: List ( List ( Int, String ) )
  }

init : String -> String -> ( Model, Cmd Msg )
init pollId apiAddress = 
  let model = Model pollId ( Poll "" "" [] ) apiAddress 0
  in ( model, getPollRequest model )



-- UPDATE
type Msg 
  = GetPollResponse ( Result Http.Error Poll )
  | GoToVote

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GetPollResponse result ->
      case result of
        Ok newPoll ->
          ( { model | poll = newPoll, step = List.length newPoll.timeline - 1 }, Cmd.none )

        Err _ ->
          ( model, Cmd.none )

    GoToVote ->
      ( model, Navigation.load ( "/vote/" ++ model.pollId ) )

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
      [ ( 12, "highest choice" )
      , ( 10, "higher choice" )
      , ( 8, "lower choice" )
      , ( 3, "lowest choice" )
      ]
    , [ ( 12, "highest choice" )
      , ( 12, "higher choice" )
      , ( 9, "lower choice" )
      ]
    , [ ( 17, "higher choice" )
      , ( 16, "highest choice" )
      ]
    , [ ( 1, "Choice 1" )
      , ( 2, "Choice 2" )
      , ( 3, "Choice 3" )
      , ( 4, "Choice 4" )
      , ( 5, "Choice 5" )
      , ( 1, "Choice 6" )
      , ( 2, "Choice 7" )
      , ( 3, "Choice 8" )
      , ( 4, "1234567890 1234567890 1234567890" )
      , ( 5, "WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW" )
      ]
    ]



-- VIEW
view : Model -> Html Msg
view model =
  let
      round = 
        case listGet model.step model.poll.timeline of
          Nothing -> []
          Just newRound -> newRound
  in
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

    , div [ class "fv-main-code" ] [ text "," ]

    , div 
        [ class "flex justify-between items-center" ]
        [ div [ class "w-8" ] []
        , h2 [ class "fv-main-header" ] [ text "Timeline" ]
        , div [ class "fv-main-code w-8 text-right" ] [ text "=" ]
        ]

    , div 
        [ class "flex justify-between items-center mt-2" ]
        [ button 
          [ class "fv-nav-btn"] 
          [ FeatherIcons.arrowLeft
            |> FeatherIcons.withSize 22
            |> FeatherIcons.withStrokeWidth 2
            |> FeatherIcons.toHtml [] ]

        , input 
            [ class "flex-grow mx-2 fv-slider"
            , type_ "range" ] 
            []

        , button 
          [ class "fv-nav-btn" ] 
          [ FeatherIcons.arrowRight
            |> FeatherIcons.withSize 22
            |> FeatherIcons.withStrokeWidth 2
            |> FeatherIcons.toHtml [] ]
        ]

    , renderTimeline round <| initTimeline round

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
  }

initTimeline : List ( Int, String ) -> TimelineConfig
initTimeline round =
  let
    height = 
        100 + 30 * List.length round - 1
  in
  TimelineConfig 375 ( toFloat height ) 30

-- Lifted from list-extra
listGet : Int -> List a -> Maybe a
listGet index list =
    if index < 0 then
        Nothing
    else
        List.head <| List.drop index list

xScale : TimelineConfig -> ContinuousScale Float
xScale config =
  Scale.linear ( 0, config.width - 2 * config.padding ) ( 0, 5 )

yScale : TimelineConfig -> List ( Int, String ) -> BandScale String
yScale config model =
  List.map Tuple.second model
    |> Scale.band { defaultBandConfig | paddingInner = 0.2, paddingOuter = 0.2 } ( 0, config.height - 2 * config.padding )

xAxis : TimelineConfig -> SvgCore.Svg msg
xAxis config =
  Axis.top [ Axis.tickCount 5 ] <| xScale config

yAxis : TimelineConfig -> List ( Int, String ) -> SvgCore.Svg msg
yAxis config model =
  -- List.map so that empty string is shown as ticks
  Axis.left [] <| Scale.toRenderable identity <| yScale config model

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
          [ SvgAttributes.class [ "text-blue-500 fill-current text-sm" ] 
          , SvgInPx.x <| config.padding / 4
          , SvgInPx.y <| Scale.convert scale choice + ( Scale.bandwidth scale / 2 )
          , SvgAttributes.textAnchor SvgTypes.AnchorStart
          , SvgAttributes.dominantBaseline SvgTypes.DominantBaselineMiddle
          ]
          [ SvgCore.text <| truncateChoice choice ]
    ]

truncateChoice : String -> String
truncateChoice choice =
  if String.length choice > 27 then
    String.slice 0 27 choice  ++ "..."
  else
    choice

renderTimeline : List ( Int, String ) -> TimelineConfig -> SvgCore.Svg msg
renderTimeline model config =
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
        [ yAxis config model ]
    , Svg.g [ SvgAttributes.transform [ SvgTypes.Translate config.padding config.padding ] ] <|
        List.map ( row config <| yScale config model ) model
    ]