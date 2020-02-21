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
  let
    titleQuotation = 
      if model.title == "" then
        ""
      else
        "\""
  in
  div [ class "container p-4 font-mono mx-auto text-sm text-orange-500" ]
    ( List.concat
      [ [ div [ class "flex justify-between" ]
            [ h1 [ class "" ] [ text "poll" ]
            , h3 [ class "" ] [ text "= {" ]
            ]
        
        , div [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "text-4xl text-blue-500" ] [ text "title" ]
            , h3 [ class "w-8 text-right" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ h3 [ class "w-8"] [ text titleQuotation ]
            , input [ class "w-full bg-blue-900 text-md text-blue-100 placeholder-blue-100 rounded p-2"
                    , class "hover:bg-blue-700"
                    , class "focus:bg-blue-700"
                    , placeholder "-- Enter a poll title"
                    , value model.title
                    , onInput ChangeTitle 
                    ] [] 
            , h3 [class "w-8 text-right" ] [ text titleQuotation ]
            ] 
        
        
        , h3 [class "text-left pb-6" ] [ text "," ]

        , div [class "flex justify-between items-center" ]
          [ div [ class "w-8" ] [ text "" ]
          , h2 [ class "text-4xl text-blue-500" ] [text "choices" ]
          , h3 [ class "w-8 text-right" ] [text "= [" ]
          ]
        ]

      , Array.toList <| Array.indexedMap renderChoice model.choices

      , [ h3 [ class "text-left m-auto pb-6" ] [ text "] }" ]
        , button 
          [ class "text-4xl w-full bg-orange-500 text-orange-100 shadow-lg rounded py-2" 
          , class "hover:bg-orange-700"
          , onClick MakePollRequest 
          ] [ text "create poll" ] 
        ]
      ] 
    )
    
    

renderChoice : Int -> String -> Html Msg
renderChoice index choice =
  let 
    placeholderValue = 
      if index == 0 then
        "-- Enter a poll choice"
      else
        "-- Enter another choice"
    
    startQuotation = 
      if choice == "" then
        ""
      else if index == 0 then
        "\""
      else
        ", \""

    endQuotation =
      if choice == "" then
        ""
      else
        "\""

  in
  div [ class "flex justify-between items-center pb-2" ] 
    [ h3 [ class "w-8"] [ text startQuotation ]
    , input [ class "w-full bg-blue-900 text-blue-100 text-md placeholder-blue-100 rounded p-2"
            , class "hover:bg-blue-700"
            , class "focus:bg-blue-700"
            , placeholder placeholderValue
            , value choice
            , onInput ( ChangeChoice index ) 
            ] []
    , h3 [ class "w-8 text-right"] [ text endQuotation ]
    ]
  