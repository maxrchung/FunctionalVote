module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array exposing (..)
import Http
import Browser.Navigation as Navigation
import Json.Decode as Decode
import Json.Encode as Encode
import Url
import Url.Parser as Parser exposing ((</>))
import Url.Parser.Query as Query

-- MAIN
main = 
  Browser.application 
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    , onUrlRequest = UrlRequested
    , onUrlChange = UrlChanged
    }

-- MODEL
type alias Model = 
  { key: Navigation.Key
  , route : Maybe Route
  , title : String
  , choices : Array String }

init : () -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key = 
  ( Model key (Parser.parse routeParser url) "" (Array.fromList ["", "", ""]), Cmd.none )

type Route 
  = Home
  | Vote Int
  | Poll Int

routeParser : Parser.Parser (Route -> a) a
routeParser =
  Parser.oneOf
    [ Parser.map Home Parser.top
    , Parser.map Vote (Parser.s "vote" </> Parser.int)
    , Parser.map Poll (Parser.s "poll" </> Parser.int)
    ]

-- UPDATE
type Msg 
  = ChangeTitle String
  | ChangeChoice Int String
  | MakePollRequest
  | MakePollResponse (Result Http.Error String)
  | UrlRequested Browser.UrlRequest
  | UrlChanged Url.Url

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChangeTitle newTitle ->
      ({ model | title = newTitle }, Cmd.none)
      
    ChangeChoice index newChoice ->
      ({ model | choices = Array.set index newChoice model.choices }, Cmd.none)

    MakePollRequest ->
      (model, makePollRequest model)

    MakePollResponse result ->
      case result of
        Ok pollId ->
          (model, Navigation.load ("/poll/" ++ pollId) )
        Err _ ->
          (model, Cmd.none)

    UrlRequested urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Navigation.pushUrl model.key (Url.toString url) )

        Browser.External href ->
          ( model, Navigation.load href )

    UrlChanged url ->
      ( { model | route = Parser.parse routeParser url }, Cmd.none )
      

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

-- VIEW
view : Model -> Browser.Document Msg
view model =
  { title = "Functional Vote" 
  , body = 
    case model.route of 
      Just route ->
        case route of
          Home ->
            [ div []
              ([ input [ placeholder "Title", value model.title, onInput ChangeTitle ] [] ] ++
              Array.toList (Array.indexedMap renderChoice model.choices) ++
              [ button [onClick MakePollRequest] [ text "Create Poll" ] ])
            ]
          Poll id->
            [ text "Poll"
            ]
          Vote id ->
            [ text "Vote"
            ]
      Nothing ->
        [ text "Invalid URL!!!!"
        ]
  }

renderChoice : Int -> String -> Html Msg
renderChoice index choice =
  input [ placeholder "Choice", value choice, onInput (ChangeChoice index) ] []

makePollRequest : Model -> Cmd Msg
makePollRequest model =
  Http.post
    { url = "http://localhost:4000/poll/"
    , body = Http.jsonBody (makePollJSON model)
    , expect = Http.expectJson MakePollResponse makePollDecoder
    }

makePollJSON : Model -> Encode.Value
makePollJSON model = 
  Encode.object
    [ ( "title", Encode.string model.title )
    , ( "choices", Encode.array Encode.string model.choices )
    ]

makePollDecoder : Decode.Decoder String
makePollDecoder =
  Decode.field "id" (Decode.field "id" Decode.string)