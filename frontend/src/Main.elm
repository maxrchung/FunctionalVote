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

-- MAIN
main = 
    Browser.element 
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view 
        }

-- MODEL
type alias Model = 
    { title : String
    , choices : Array String }

init : () -> (Model, Cmd Msg)
init _ = (Model "" (Array.fromList ["", "", ""]), Cmd.none)

-- UPDATE
type Msg 
    = ChangeTitle String
    | ChangeChoice Int String
    | MakePollRequest
    | MakePollResponse (Result Http.Error String)

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
            Ok pollID ->
                (model, Navigation.load ("/poll/" ++ pollID) )
            Err _ ->
                (model, Cmd.none)
            

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none

-- VIEW
view : Model -> Html Msg
view model =
    div []
        ([ input [ placeholder "Title", value model.title, onInput ChangeTitle ] [] ] ++
        Array.toList (Array.indexedMap renderChoice model.choices) ++
        [ button [onClick MakePollRequest] [ text "Create Poll" ] ])


renderChoice : Int -> String -> Html Msg
renderChoice index choice =
    input [ placeholder "Choice", value choice, onInput (ChangeChoice index) ] []

makePollRequest : Model -> Cmd Msg
makePollRequest model =
    Http.post
        { url = "/poll/"
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
    Decode.field "data" (Decode.field "image_url" Decode.string)