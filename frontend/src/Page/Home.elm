module Page.Home exposing ( .. )

import Browser.Navigation as Navigation
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Http.Detailed
import Array
import Json.Decode as Decode
import Json.Encode as Encode



-- MODEL
type alias Model = 
  { key : Navigation.Key
  , title : String
  , showError: Bool
  , error : String
  , choices : Array.Array String
  , apiAddress: String }

init : Navigation.Key -> String -> ( Model, Cmd Msg )
init key apiAddress = 
  ( Model key "" False "" (Array.fromList ["", ""]) apiAddress, Cmd.none )



-- UPDATE
type Msg 
  = ChangeTitle String
  | ChangeChoice Int String
  | MakePollRequest
  | MakePollResponse ( Result ( Http.Detailed.Error String ) ( Http.Metadata, Int ) )

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChangeTitle newTitle ->
      ( { model | title = newTitle, showError = False }, Cmd.none )
      
    ChangeChoice index newChoice ->
      let 
        updatedChoices = Array.set index newChoice model.choices
        newChoices = 
          if index == Array.length model.choices - 1  then
            Array.push "" updatedChoices
          else
            updatedChoices
      in
      ( { model | choices = newChoices, showError = False }, Cmd.none )

    MakePollRequest ->
      ( model, makePollRequest model )

    MakePollResponse result ->
      case result of
        Ok ( _, pollId ) ->
          ( model, Navigation.pushUrl model.key ( "/vote/" ++ String.fromInt pollId ) )
        Err error ->
          let 
            newError =
              case error of
                Http.Detailed.BadStatus _ body ->
                  body
                _ ->
                  "Unable to create poll. The website may be down for maintenace. Please try again later."
          in
          ( { model | showError = True, error = newError }, Cmd.none )

makePollRequest : Model -> Cmd Msg
makePollRequest model =
  Http.post
    { url = model.apiAddress ++ "/poll/"
    , body = Http.jsonBody ( makePollJson model )
    , expect = Http.Detailed.expectJson MakePollResponse makePollDecoder
    }

makePollJson : Model -> Encode.Value
makePollJson model = 
  Encode.object
    [ ( "title", Encode.string model.title )
    , ( "choices", Encode.array Encode.string model.choices )
    ]

makePollDecoder : Decode.Decoder Int
makePollDecoder =
  Decode.field "data" (Decode.field "id" Decode.int )



-- VIEW
view : Model -> Html Msg
view model =
  Html.form [ onSubmit MakePollRequest ]
      [ div [ class "fv-main-text" ]
          [ text "-- Welcome to Functional Vote! Enter a question and choices below to create a ranked-choice poll." ]
      
      , div [ class "flex justify-between" ]
          [ h1 [ class "fv-main-code" ] [ text "poll" ]
          , div [ class "fv-main-code" ] [ text "={" ]
          ]
      
      , div [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] []
          , h2 [ class "fv-main-header" ] [ text "Question" ]
          , div [ class "fv-main-code w-8 text-right" ] [ text "=" ]
          ]

      , div [ class "flex justify-between items-center py-2" ]
          [ div [ class "fv-main-code w-8"] [ text "\"" ]
          , input [ class "fv-main-input"
                  , errorClass model.showError
                  , placeholder "-- Enter a question"
                  , value model.title
                  , onInput ChangeTitle 
                  ] [] 
          , div [class "fv-main-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "fv-main-code" ] [ text "," ]

      , div [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] [ text "" ]
          , h2 [ class "fv-main-header" ] [ text "Choices" ]
          , div [ class "fv-main-code w-8 text-right" ] [text "=[" ]
          ]

      , div
          []
          ( Array.toList <| Array.indexedMap ( renderChoice model.showError ) model.choices )

      , div [ class "fv-main-code pb-2" ] [ text "]}" ]
      
      , div [ class "flex justify-between pb-1" ]
          [ div [ class "w-8" ] [ text "" ]
          , button 
              [ class "fv-main-btn"
              , type_ "submit"
              ] [ text "Create Poll" ] 
          , div [ class "w-8 text-right" ] [ text "" ]
          ]

      , div [class "flex justify-between" ]
          [ div [ class "w-8" ] [ text "" ]
          , div [ class "w-full fv-main-text fv-main-text-error" ] [ errorText model.error ] 
          , div [ class "w-8 text-right" ] [ text "" ]
          ]
      ]

renderChoice : Bool -> Int -> String -> Html Msg
renderChoice showError index choice =
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
  div [ class "flex justify-between items-center py-2" ] 
    [ div [ class "fv-main-code w-8"] [ text startQuotation ]
    , input [ class "fv-main-input"
            , errorClass showError
            , placeholder placeholderValue
            , value choice
            , onInput ( ChangeChoice index ) 
            ] []
    , div [ class "fv-main-code w-8 text-right"] [ text "\"" ]
    ]
  
errorClass : Bool -> Attribute a
errorClass showError =
  if showError then
    class "fv-main-input-error"
  else
    class ""

errorText : String -> Html a
errorText error =
  if String.isEmpty error then
    text ""
  else
    text <| "-- " ++ error
