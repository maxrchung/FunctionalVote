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
  ( Model "" (Array.fromList ["", ""]), Cmd.none )



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
  div [ class "container font-mono grid grids-cols-12 gap-4 mx-auto text-center text-2xl text-orange-500" ]
    ( List.concat
      [ [ h1 [ class "col-span-1 m-auto" ] [ text "poll" ]
        , div [ class "col-span-10" ] []
        , h3 [ class "col-span-1 col-end-13 m-auto w-16" ] [ text "= {" ]

        , h2 [ class "col-span-10 col-start-2 text-6xl text-blue-500" ] [ text "title" ]
        , h3 [ class "col-span-1 col-end-13 m-auto" ] [ text "=" ]

        , h3 [ class "col-span-1 m-auto w-16"] [ text "\"" ]
        , input [ class "col-span-10 text-black w-full text-4xl"
                , placeholder "-- Enter a title"
                , value model.title
                , onInput ChangeTitle 
                ] [] 
        , h3 [class "col-span-1 m-auto w-16" ] [ text "\"" ]
        , h3 [class "col-span-1 text-left m-auto" ] [ text "," ]
        , div [class "col-span-11" ] []

        , h2 [ class "col-span-10 col-start-2 text-6xl text-blue-500" ] [text "choices" ]
        , h3 [ class "col-span-1 col-end-13 m-auto" ] [text "= [" ]
        ] 

      , List.concat <| Array.toList <| Array.indexedMap renderChoice model.choices

      , [ h3 [ class "col-span-1 text-left m-auto" ] [ text "]}" ]
        , div [ class "col-span-11" ] []

        , button [ class "col-span-12 text-6xl bg-orange-500 text-white" 
                 , onClick MakePollRequest 
                 ] [ text "create poll" ] ]
      ] )

renderChoice : Int -> String -> List (Html Msg)
renderChoice index choice =
  let 
    placeholderValue = 
      if index == 0 then
        "-- Enter a choice"
      else
        "-- Enter another choice"
  in
  [ h3 [ class "col-span-1 m-auto"] [ text "\"" ]
  , input [ class "col-span-10 text-black text-4xl"
      , placeholder placeholderValue
      , value choice
      , onInput (ChangeChoice index) 
      ] []
  , h3 [ class "col-span-1 m-auto"] [ text "\"" ]
  ]
  