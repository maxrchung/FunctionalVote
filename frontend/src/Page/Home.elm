module Page.Home exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Array
import Http
import Browser.Navigation as Navigation
import Json.Decode as Decode
import Json.Encode as Encode



-- MODEL
type alias Model = 
  { title : String
  , choices : Array.Array String }

init : ( Model, Cmd Msg )
init = 
  ( Model "" (Array.fromList ["", "", ""]), Cmd.none )



-- UPDATE
type Msg 
  = ChangeTitle String
  | ChangeChoice Int String
  | MakePollRequest
  | MakePollResponse (Result Http.Error Int)

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
          (model, Navigation.load ("/vote/" ++ String.fromInt pollId) )
        Err _ ->
          (model, Cmd.none)

makePollRequest : Model -> Cmd Msg
makePollRequest model =
  Http.post
    { url = "http://localhost:4000/poll/"
    , body = Http.jsonBody (makePollJson model)
    , expect = Http.expectJson MakePollResponse makePollDecoder
    }

makePollJson : Model -> Encode.Value
makePollJson model = 
  Encode.object
    [ ( "title", Encode.string model.title )
    , ( "choices", Encode.array Encode.string model.choices )
    ]

makePollDecoder : Decode.Decoder Int
makePollDecoder =
  Decode.field "data" (Decode.field "id" Decode.int)



-- VIEW
view : Model -> Html Msg
view model =
  div [ class "container mx-auto flex flex-col font-mono text-6xl text-white" ]
    ( List.concat
      [ [ h1 [] [ text "poll = {" ]
        , h2 [] [ text "title = " ]
        , div [ class "flex" ]
          [ text "\""
          , input [ class "text-black"
                  , placeholder "-- Enter a title"
                  , value model.title
                  , onInput ChangeTitle 
                  ] [] 
          , text "\""
          ]
        , h2 [] [text "choices = [" ]
        ] 
      , Array.toList (Array.indexedMap renderChoice model.choices)
      , [ h2 [] [text "]" ]
        , h2 [] [text "}" ]
        , button [ onClick MakePollRequest ] [ text "make poll" ] ]
      ] )

renderChoice : Int -> String -> Html Msg
renderChoice index choice =
  let 
    placeholderValue = 
      if index == 0 then
        "-- Enter a choice"
      else
        "-- Enter another choice"
  in
  input [ class "text-black"
        , placeholder placeholderValue
        , value choice
        , onInput (ChangeChoice index) 
        ] []