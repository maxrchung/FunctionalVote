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
  { key : Navigation.Key
  , title : String
  , choices : Array.Array String }

init : Navigation.Key -> ( Model, Cmd Msg )
init key = 
  ( Model key "" (Array.fromList ["", ""]), Cmd.none )



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
      ( { model | title = newTitle }, Cmd.none )
      
    ChangeChoice index newChoice ->
      let updatedChoices = Array.set index newChoice model.choices
      in
      if index == Array.length model.choices - 1  then
        ( { model | choices = Array.push "" updatedChoices }, Cmd.none )
      else
        ( { model | choices = updatedChoices }, Cmd.none )

    MakePollRequest ->
      ( model, makePollRequest model )

    MakePollResponse result ->
      case result of
        Ok pollId ->
          ( model, Navigation.pushUrl model.key ( "/vote/" ++ String.fromInt pollId ) )
        Err _ ->
          ( model, Cmd.none )

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
  Html.form [ class "font-mono mx-auto text-sm text-orange-500" , onSubmit MakePollRequest ]
    ( List.concat
      [ [ h2 [ class "font-sans text-orange-500 text-md" ]
            [ text "-- Welcome to Functional Vote! To create a new ranked choice poll, enter a question and choices below." ]
        
        , div [ class "flex justify-between" ]
            [ h1 [ class "opacity-25" ] [ text "poll" ]
            , h3 [ class "opacity-25" ] [ text "={" ]
            ]
        
        , div [ class "flex justify-between items-center" ]
            [ div [ class "w-8" ] []
            , h2 [ class "font-sans text-2xl text-blue-500 font-bold " ] [ text "Question" ]
            , h3 [ class "w-8 text-right opacity-25" ] [ text "=" ]
            ]

        , div [ class "flex justify-between items-center" ]
            [ h3 [ class "w-8 opacity-25"] [ text "\"" ]
            , input [ class "font-sans rounded w-full bg-gray-900 border-2 border-blue-700 text-md text-blue-100 placeholder-blue-100 p-2 outline-none shadow-md"
                    , class "hover:bg-blue-900 hover:shadow-lg"
                    , class "focus:bg-blue-900"
                    , placeholder "-- Enter a question"
                    , value model.title
                    , onInput ChangeTitle 
                    ] [] 
            , h3 [class "w-8 text-right opacity-25" ] [ text "\"" ]
            ] 
        
        
        , h3 [class "text-left opacity-25" ] [ text "," ]

        , div [class "flex justify-between items-center" ]
            [ div [ class "w-8" ] [ text "" ]
            , h2 [ class "font-sans text-2xl text-blue-500 font-bold" ] [ text "Choices" ]
            , h3 [ class "w-8 text-right opacity-25" ] [text "=[" ]
            ]
        ]

      , Array.toList <| Array.indexedMap renderChoice model.choices

      , [ h3 [ class "text-left m-auto pb-2 opacity-25" ] [ text "]}" ]
        
        , div [class "flex justify-between items-center" ]
            [ div [ class "w-8" ] [ text "" ]
            , button 
                [ class "font-sans appearance-none rounded-full text-2xl w-full bg-orange-500 text-orange-100 shadow-lg py-2 font-bold shadow-md" 
                , class "hover:bg-orange-700 hover:shadow-lg"
                , class "focus:outline-none"
                , type_ "submit"
                ] [ text "Create Poll" ] 
            , h3 [ class "w-8 text-right" ] [ text "" ]
            ]
        ]
      ] 
    )

renderChoice : Int -> String -> Html Msg
renderChoice index choice =
  let 
    placeholderValue = 
      if index == 0 then
        "-- Enter a choice"
      else
        "-- Enter another choice"
    
    startQuotation = 
      if index == 0 then
        "\""
      else
        ",\""

  in
  div [ class "flex justify-between items-center pb-2" ] 
    [ h3 [ class "w-8 opacity-25"] [ text startQuotation ]
    , input [ class "font-sans rounded w-full bg-gray-900 border-2 border-blue-700 text-blue-100 text-md placeholder-blue-100 p-2 outline-none shadow-md"
            , class "hover:bg-blue-900 hover:shadow-lg"
            , class "focus:bg-blue-900"
            , placeholder placeholderValue
            , value choice
            , onInput ( ChangeChoice index ) 
            ] []
    , h3 [ class "w-8 text-right opacity-25"] [ text "\"" ]
    ]
  
