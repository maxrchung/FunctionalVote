module Page.Home exposing ( .. )

import Array
import Array.Extra
import Browser.Dom as Dom
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Http.Detailed
import Json.Decode as Decode
import Json.Encode as Encode
import Task



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
  ( Model key "" False "" ( Array.fromList [ "", "" ] ) apiAddress
  , Task.attempt ( \_ -> NoOp ) ( Dom.focus "question" )
  )



-- UPDATE
type Msg
  = ChangeTitle String
  | ChangeChoice Int String
  | MakePollRequest
  | MakePollResponse ( Result ( Http.Detailed.Error String ) ( Http.Metadata, String ) )
  | RemoveChoice Int
  | ScrollTo String
  | NoOp

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
                  "Unable to create poll. The website may be down for maintenance. Please try again later."
          in
          ( { model | showError = True, error = newError }, Cmd.none )

    RemoveChoice index ->
      let newChoices = Array.Extra.removeAt index model.choices
      in ( { model | choices = newChoices, showError = False }, Cmd.none )

    ScrollTo tag ->
      ( model
      , Task.attempt
          ( \_ -> NoOp )
          ( Dom.getElement tag |> Task.andThen (\info -> Dom.setViewport 0 info.element.y) )
      )

    NoOp ->
      ( model, Cmd.none )

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
  Html.form
    [ onSubmit MakePollRequest ]
    [ div [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "--" ]
        , p [ class "fv-text w-full" ]
            [ text "Welcome to Functional Vote! This website lets you create and share free online polls that use "
            , a
                [ href "#ranked-choice"
                , target "_self"
                ]
                [ text "ranked-choice voting" ]
            , text ". Create a new poll by entering a question and a few choices." ]

        , div [ class "w-8" ] []
        ]

    , div [ class "flex justify-between" ]
        [ h1 [ class "fv-code opacity-25" ] [ text "poll" ]
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
            , errorClass model.showError
            , id "question"
            , placeholder "Enter a question"
            , value model.title
            , onInput ChangeTitle
            ] []
        , div [class "fv-code w-8 text-right" ] [ text "\"" ]
        ]

    , div [ class "fv-code" ] [ text "," ]

    , div [ class "flex justify-between items-center" ]
        [ div [ class "w-8" ] []
        , h2 [ class "fv-header" ] [ text "Choices" ]
        , div [ class "fv-code w-8 text-right" ] [ text "=" ]
        ]

      , let choicesLength = Array.length model.choices
        in
        div [] ( Array.toList <| Array.indexedMap ( renderChoice choicesLength model.showError ) model.choices )

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
          , p [ class "fv-text w-full" ] [ text "Check out a few of our example polls to see how the voting process works. Click a question and vote for your favorite preferences." ]
          , div [ class "w-8" ] []
          ]

      , div [ class "flex justify-between" ]
          [ div [ class "fv-code opacity-25" ] [ text "examples" ]
          , div [ class "fv-code" ] [ text "=" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text "[\"" ]
          , div [ class "w-full text-center" ]
              [ a [ href "/vote/bjDm9VD" ] [ text "Favorite color?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full text-center" ]
              [ a [ href "/vote/TlR007Q" ] [ text "Favorite season of the year?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full text-center" ]
              [ a [ href "/vote/oFDFtDwq" ] [ text "Pineapple on pizza?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full text-center" ]
              [ a [ href "/vote/Q2tobIMV" ] [ text "How do you pronounce GIF?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "flex justify-between items-center my-2" ]
          [ div [ class "fv-code w-8" ] [ text ",\"" ]
          , div [ class "w-full text-center" ]
              [ a [ href "/vote/DVmeUPww" ] [ text "How do you like your eggs?" ] ]
          , div [ class "fv-code w-8 text-right" ] [ text "\"" ]
          ]

      , div [ class "fv-code" ] [ text "]" ]

      , div [ class "fv-break" ] [ text "--" ]

      , div [ class "flex justify-between items-center" ]
          [ div [ class "fv-code w-8" ] [ text "{-" ]

          , h2 [ class "fv-header mb-1" ]
              [ text "Why Functional Vote?" ]

          , div [ class "w-8" ] []
          ]

      , div [ class "flex" ]
          [ div [ class "w-8" ] []

          , div [ class "w-full" ]
              [ p [ class "fv-text" ]
                [ text "Functional Vote was started by us ("
                , a [ href "https://github.com/maxrchung"
                    , target "_blank" ] [ text "Max" ]
                , text " and "
                , a [ href "https://github.com/Xenocidel"
                    , target "_blank" ] [ text "Aaron" ]
                , text ") when we couldn't easily find an online resource to make ranked-choice polls. We like working on software projects in our free time, so naturally, we tried to solve our own problem. We added a little educational twist, using only functional programming languages, and with Elm and Elixir in tow, we began Functional Vote."
                ]

              , div [ class "fv-break" ] [ text "--" ]

              , h2
                  [ class "fv-header mb-1"
                  , id "ranked-choice"
                  ]
                  [ text "Why Ranked-Choice?" ]

              , p [ class "fv-text mb-6" ] [ text "In a traditional voting system, voters may only vote for a single choice out of many options. Ranked-choice voting, instead, allows voters to rank multiple options in order of preference. If a voter's first preferred option does not gain enough collective votes to pass a threshold, that voter's second choice is counted instead, then third, and so forth." ]

              , p [ class "fv-text mb-6" ] [ text "Ranked-choice voting is typically fairer than traditional voting because preferential ranking is more flexible than casting a single vote in stone. Voters are incentivized to vote for their preferred options rather than for popular choices." ]

              , p [ class "fv-text mb-6" ] [ text "There are many resources online that explain ranked-choice voting in greater detail. We particularly like "
                  , a
                      [ href "https://www.youtube.com/user/CGPGrey"
                      , target "_blank"
                      ]
                      [ text "CGP Grey" ]
                  , text "'s video on this topic since that's how we were first introduced to the concept:"
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
            , errorClass showError
            , placeholder placeholderValue
            , value choice
            , onInput ( ChangeChoice index )
            ]
            []

        , if index == choicesLength - 1 then
              div [] []
            else
              button
                [ class "fv-nav-btn ml-2 hover:bg-blue-900 focus:bg-blue-900"
                , onClick <| RemoveChoice index
                , type_ "button"
                , tabindex -1
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