module Page.Home exposing ( .. )

import Array
import Array.Extra
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Http.Detailed
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
  | MakePollResponse ( Result ( Http.Detailed.Error String ) ( Http.Metadata, String ) )
  | RemoveChoice Int

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
          ( model, Navigation.pushUrl model.key ( "/vote/" ++ pollId ) )
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

    RemoveChoice index ->
      let newChoices = Array.Extra.removeAt index model.choices
      in ( { model | choices = newChoices }, Cmd.none )

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

makePollDecoder : Decode.Decoder String
makePollDecoder =
  Decode.field "data" ( Decode.field "poll_id" Decode.string )



-- VIEW
view : Model -> Html Msg
view model =
  let choicesLength = Array.length model.choices
  in
  Html.form [ onSubmit MakePollRequest ]
      [ div [ class "fv-text" ]
          [ text "-- Welcome to Functional Vote! Enter a question and a few choices below to create a new ranked-choice poll." ]
      
      , div [ class "flex justify-between" ]
          [ h1 [ class "fv-code" ] [ text "poll" ]
          , div [ class "fv-code" ] [ text "={" ]
          ]
      
      , div [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] []
          , h2 [ class "fv-header" ] [ text "Question" ]
          , div [ class "fv-code w-8 text-right" ] [ text "=" ]
          ]

      , div [ class "flex justify-between items-center py-2" ]
          [ div [ class "fv-code w-8"] [ text "\"" ]
          , input [ class "fv-input"
                  , errorClass model.showError
                  , placeholder "-- Enter a question"
                  , value model.title
                  , onInput ChangeTitle 
                  ] [] 
          , div [class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "fv-code" ] [ text "," ]

      , div [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] [ text "" ]
          , h2 [ class "fv-header" ] [ text "Choices" ]
          , div [ class "fv-code w-8 text-right" ] [text "=[" ]
          ]

      , div
          []
          ( Array.toList <| Array.indexedMap ( renderChoice choicesLength model.showError ) model.choices )

      , div [ class "fv-code pb-2" ] [ text "]}" ]
      
      , div [ class "flex justify-between pb-1" ]
          [ div [ class "w-8" ] [ text "" ]
          , button 
              [ class "fv-btn"
              , type_ "submit"
              ] [ text "Create Poll" ] 
          , div [ class "w-8 text-right" ] [ text "" ]
          ]

      , div [class "flex justify-between" ]
          [ div [ class "w-8" ] [ text "" ]
          , div [ class "w-full fv-text fv-text-error" ] [ errorText model.error ] 
          , div [ class "w-8 text-right" ] [ text "" ]
          ]
      ]

renderChoice : Int -> Bool -> Int -> String -> Html Msg
renderChoice choicesLength showError index choice =
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
    [ div [ class "fv-code w-8"] [ text startQuotation ]

    , div [ class "flex justify-between items-center w-full" ]
        [ input
            [ class "fv-input"
            , errorClass showError
            , placeholder placeholderValue
            , value choice
            , onInput ( ChangeChoice index ) 
            ] 
            []

        , if choicesLength < 4 then
              div [] []
            else
              button
                  [ class "flex-shrink-0 ml-2 fv-nav-btn bg-gray-900 border-2 border-blue-500 hover:bg-blue-900"
                  , onClick <| RemoveChoice index
                  , type_ "button"
                  ]
                  [ FeatherIcons.x
                      |> FeatherIcons.toHtml []
                  ]
        ]

    , div [ class "fv-code w-8 text-right"] [ text "\"" ]
    ]
  
errorClass : Bool -> Attribute a
errorClass showError =
  if showError then
    class "fv-input-error"
  else
    class ""

errorText : String -> Html a
errorText error =
  if String.isEmpty error then
    text ""
  else
    text <| "-- " ++ error
