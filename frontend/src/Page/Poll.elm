module Page.Poll exposing ( .. )

import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Json.Decode as Decode



-- MODEL
type alias Model = 
  { pollId: String
  , poll: Poll
  , apiAddress: String
  }

type alias Poll =
  { title: String
  , winner: String
  , timeline: List ( List ( Int, String ) )
  }

init : String -> String -> ( Model, Cmd Msg )
init pollId apiAddress = 
  let model = Model pollId ( Poll "" "" [] ) apiAddress
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
          ( { model | poll = newPoll }, Cmd.none )

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
    ]



-- VIEW
view : Model -> Html Msg
view model =
  div [] 
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
        [ class "flex justify-between items-center my-3" ]
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