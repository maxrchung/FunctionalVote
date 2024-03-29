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
import Shared



-- MODEL
type alias Model =
  { key : Navigation.Key
  , title : String
  , showError: Bool
  , error : String
  , choices : Array.Array String
  , apiAddress: String
  , useRecaptcha: Bool
  , preventMultipleVotes: Bool
  }

init : Navigation.Key -> String -> Model
init key apiAddress =
  Model key "" False "" ( Array.fromList [ "", "" ] ) apiAddress False False



-- UPDATE
type Msg
  = ChangeTitle String
  | ChangeChoice Int String
  | MakePollRequest
  | MakePollResponse ( Result ( Http.Detailed.Error String ) ( Http.Metadata, String ) )
  | RemoveChoice Int
  | ToggleRecaptcha
  | ToggleMultipleVotes

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChangeTitle newTitle ->
      ( { model | title = newTitle, showError = False }, Cmd.none )

    ChangeChoice index newChoice ->
      let
        updatedChoices = Array.set index newChoice model.choices
        newChoices =
          if index == Array.length model.choices - 1 && Array.length model.choices < 100 then
            Array.push "" updatedChoices
          else
            updatedChoices
      in ( { model | choices = newChoices, showError = False }, Cmd.none )

    MakePollRequest -> ( model, makePollRequest model )

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
                  "Unable to create poll. The website may be down for maintenance. Please try again later."
          in ( { model | showError = True, error = newError }, Cmd.none )

    RemoveChoice index ->
      let newChoices = Array.Extra.removeAt index model.choices
      in ( { model | choices = newChoices, showError = False }, Cmd.none )

    ToggleRecaptcha -> ( { model | useRecaptcha = not model.useRecaptcha, showError = False }, Cmd.none )

    ToggleMultipleVotes -> ( { model | preventMultipleVotes = not model.preventMultipleVotes, showError = False }, Cmd.none )

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
    , ( "use_recaptcha", Encode.bool model.useRecaptcha )
    , ( "prevent_multiple_votes", Encode.bool model.preventMultipleVotes )
    ]

makePollDecoder : Decode.Decoder String
makePollDecoder =
  Decode.field "data" ( Decode.field "poll_id" Decode.string )



-- VIEW
view : Model -> Html Msg
view model =
  Html.form
    [ onSubmit MakePollRequest ]
    [ div [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "--" ]
        , p [ class "fv-text w-full" ]
            [ text "Welcome to Functional Vote! This website lets you create polls that use "
            , a [ href "#ranked-choice" ] [ text "ranked-choice voting" ]
            , text ". Create a new poll by filling out the form." ]
        , div [ class "w-8" ] []
        ]

    , div [ class "flex justify-between" ]
        [ h1 [ class "fv-code" ] [ text "poll" ]
        , div [ class "fv-code" ] [ text "=" ]
        ]

    , div [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "{" ]
        , h2 [ class "fv-header" ] [ text "Question" ]
        , div [ class "fv-code w-8 text-right" ] [ text "=" ]
        ]

    , div [ class "flex justify-between items-center py-2" ]
        [ div [ class "fv-code w-8"] [ text "\"" ]
        , input
            [ class "fv-input"
            , inputErrorClass model.showError
            , maxlength 100
            , placeholder "Enter a question"
            , value model.title
            , onInput ChangeTitle
            ] []
        , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
        ]

    , div [ class "fv-code" ] [ text "," ]

    , div [ class "flex justify-between items-center" ]
        [ div [ class "w-8" ] []
        , h2 [ class "fv-header" ] [ text "Choices" ]
        , div [ class "fv-code w-8 text-right" ] [ text "=" ]
        ]

      , let choicesLength = Array.length model.choices
        in div [] ( Array.toList <| Array.indexedMap ( renderChoice choicesLength model.showError ) model.choices )

      , div [ class "fv-code" ] [ text "]," ]

      , div [ class "flex justify-between items-center" ]
          [ div [ class "w-8" ] [ text "" ]
          , h2 [ class "fv-header" ] [ text "Options" ]
          , div [ class "fv-code w-8 text-right" ] [ text "=" ]
          ]

      , div [ class "flex justify-between items-center py-2" ]
          [ div [ class "fv-code w-8" ] [ text "[(" ]
          , div [ class "w-full flex items-center" ]
              [ input
                  [ checked model.preventMultipleVotes
                  , class "fv-chk"
                  , chkErrorClass model.showError
                  , type_ "checkbox"
                  ] []
              , label [ onClick ToggleMultipleVotes ] []
              , div [ class "fv-code w-8 text-center flex-shrink-0" ] [ text ",\"" ]
              , div
                  [ class "fv-text text-blue-100 cursor-pointer"
                  , onClick ToggleMultipleVotes
                  ] [ text "Prevent multiple votes from the same IP address" ]
              ]
          , div [ class "fv-code w-8 text-right" ] [ text "\")" ]
          ]

      , div [ class "flex justify-between items-center py-2" ]
          [ div [ class "fv-code w-8" ] [ text "(" ]
          , div [ class "w-full flex items-center" ]
              [ input
                  [ checked model.useRecaptcha
                  , class "fv-chk"
                  , chkErrorClass model.showError
                  , type_ "checkbox"
                  ] []
              , label [ onClick ToggleRecaptcha ] []
              , div [ class "fv-code w-8 text-center flex-shrink-0" ] [ text ",\"" ]
              , div
                  [ class "fv-text text-blue-100 cursor-pointer"
                  , onClick ToggleRecaptcha
                  ]
                  [ text "Use reCAPTCHA verification" ]
              ]
          , div [ class "fv-code w-8 text-right" ] [ text "\")" ]
          ]

      , div [ class "fv-code pb-2" ] [ text "]}" ]

      , div [ class "flex justify-between pb-1" ]
          [ div [ class "w-8" ] []
          , button
              [ class "fv-btn"
              , type_ "submit"
              ] [ text "Create Poll" ]
          , div [ class "w-8" ] []
          ]

      , div [ class "flex justify-between" ]
          [ div [ class "fv-code w-8" ] [ errorComment model.error ]
          , div [ class "w-full fv-text fv-text-error" ] [ errorText model.error ]
          , div [ class "w-8" ] []
          ]

      , div [ class "fv-break" ] [ text "--" ]

      , div [ class "flex justify-between items-center" ]
          [ div [ class "fv-code w-8" ] [ text "--" ]
          , p [ class "fv-text w-full" ] [ text "Check out a few of our example polls by clicking a question." ]
          , div [ class "w-8" ] []
          ]

      , div [ class "flex justify-between" ]
          [ div [ class "fv-code" ] [ text "examples" ]
          , div [ class "fv-code" ] [ text "=" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text "[\"" ]
          , div [ class "w-full" ] [ a [ href "/vote/bjDm9VD" ] [ text "Favorite color?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full" ] [ a [ href "/vote/TlR007Q" ] [ text "Favorite season of the year?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full" ] [ a [ href "/vote/oFDFtDwq" ] [ text "Pineapple on pizza?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full" ] [ a [ href "/vote/Q2tobIMV" ] [ text "How do you pronounce GIF?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full" ] [ a [ href "/vote/DVmeUPww" ] [ text "How do you like your eggs?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "fv-code" ] [ text "]" ]

      , div [ class "fv-break" ] [ text "--" ]

      , div [ class "flex justify-between items-center mb-6" ]
          [ div [ class "fv-code w-8" ] [ text "{-" ]

          , h2
              [ class "fv-header"
              , id "ranked-choice"
              ] [ text "Why Ranked-Choice?" ]

          , div [ class "w-8" ] []
          ]

      , div [ class "flex" ]
          [ div [ class "w-8" ] []

          , div [ class "w-full" ]
              [ p [ class "fv-text mb-6" ] [ text "In a traditional voting system, a voter only selects one choice. Ranked-choice voting, instead, allows a voter to rank all the choices to their preference. If a voter's first choice doesn't get enough votes to pass a threshold, then the voter's second choice is counted instead, then third, and so forth." ]

              , p [ class "fv-text mb-6" ] [ text "Ranked-choice voting is typically fairer than traditional voting because preferential ranking is more flexible than casting a single vote in stone. Voters are incentivized to vote for their most preferred options rather than choose a popular choice." ]

              , p [ class "fv-text mb-6" ] [ text "There are many resources online that go over ranked-choice voting in greater detail. We particularly like a video by "
                  , a
                      [ href "https://www.youtube.com/user/CGPGrey"
                      , target "_blank"
                      ]
                      [ text "CGP Grey" ]
                  , text " since that's how we were first introduced to the concept:"
                  ]

              , div [ class "embed-responsive embed-responsive-16by9"]
                  [ iframe
                    [ class "embed-responsive-item"
                    , src "https://www.youtube.com/embed/3Y3jE3B8HsE"
                    , attribute "frameborder" "none"
                    , attribute "allow" "accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
                    , attribute "allowfullscreen" "true"
                    ] []
                  ]

              , div [ class "fv-break" ] [ text "--" ]

              , h2 [ class "fv-header mb-6" ] [ text "Why Functional Vote?" ]

              , p [ class "fv-text" ]
                  [ text "Functional Vote was started by us ("
                  , a [ href "https://github.com/maxrchung"
                      , target "_blank" ] [ text "Max" ]
                  , text " and "
                  , a [ href "https://github.com/Xenocidel"
                      , target "_blank" ] [ text "Aaron" ]
                  , text ") when we couldn't easily find an online resource to make ranked-choice polls. We like working on software projects in our free time, so naturally, we tried to solve our own problem. We added a little educational twist, using only functional programming languages, and with Elm and Elixir in tow, we began Functional Vote."
                  ]
              ]
          , div [ class "w-8" ] []
          ]

      , div [ class "fv-code mt-2" ] [ text "-}" ]
      ]

renderChoice : Int -> Bool -> Int -> String -> Html Msg
renderChoice choicesLength showError index choice =
  let
    placeholderValue =
      if index == 0 then
        "Enter a choice"
      else
        "Enter another choice"

    startQuotation =
      if index == 0 then
        "[\""
      else
        ",\""
  in
  div [ class "flex justify-between items-center py-2" ]
    [ div [ class "fv-code w-8"] [ text startQuotation ]

    , div [ class "flex justify-between items-center w-full" ]
        [ input
            [ class "fv-input"
            , inputErrorClass showError
            , maxlength 100
            , placeholder placeholderValue
            , value choice
            , onInput ( ChangeChoice index )
            ] []

        , if index == choicesLength - 1 then
              div [] []
            else
              button
                [ class "fv-nav-btn fv-nav-btn-blue ml-2"
                , navBtnErrorClass showError
                , onClick <| RemoveChoice index
                , type_ "button"
                , tabindex -1
                ]
                [ Shared.renderIcon FeatherIcons.x ]
        ]

    , div [ class "fv-code w-8 text-right"] [ text "\"" ]
    ]

inputErrorClass : Bool -> Attribute a
inputErrorClass showError =
  if showError then
    class "fv-input-error"
  else
    class ""

chkErrorClass : Bool -> Attribute a
chkErrorClass showError =
  if showError then
    class "fv-chk-error"
  else
    class ""

navBtnErrorClass : Bool -> Attribute a
navBtnErrorClass showError =
  if showError then
    class "fv-nav-btn-error"
  else
    class ""

errorComment : String -> Html a
errorComment error =
  if String.isEmpty error then
    text ""
  else
    text "--"

errorText : String -> Html a
errorText error =
  if String.isEmpty error then
    text ""
  else
    text error