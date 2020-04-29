-- This file is the main entry point to https://functionalvote.com and shows our
-- use of Elm architecture, SPA routing, and Tailwind CSS.

module Main exposing ( .. )

import Browser
import Browser.Dom as Dom
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Http
import Iso8601
import Json.Decode as Decode
import Page.Home as Home
import Page.Vote as Vote
import Page.Poll as Poll
import Page.Error as Error
import Shared
import Task
import Time exposing ( Posix, Zone )
import Url
import Url.Parser as Parser exposing ( (</>) )



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
  { key : Navigation.Key
  , apiAddress : String
  , page : Page
  , env : String
  , timezone : Zone
  }

type Page
  = HomePage Home.Model
  | VotePage Vote.Model
  | PollPage Poll.Model
  | ErrorPage
  | NoPage

type Route
  = HomeRoute ( Maybe String )
  | VoteRoute String
  | PollRoute String

type alias VoteResponse =
  { title : String
  , choices : List String
  , pollId : String
  , useReCAPTCHA : Bool
  , created : Posix
  }

type alias PollResponse =
  { title : String
  , winner : String
  , tallies : List ( List ( String, Float ) )
  , pollId : String
  , created : Posix
  }

init : String -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init env url key =
  let
    apiAddress =
      if env == "production" then
        "https://FunctionalVote.com:4001"
      else
        "http://localhost:4000"
  in
  ( Model key apiAddress NoPage env Time.utc
  , Task.perform ( LoadTimezone url ) Time.here
  )

initPage : Page -> Url.Url -> Navigation.Key -> String -> ( Page, Cmd Msg )
initPage page url key apiAddress =
  case Parser.parse routeParser url of
    Just route ->
      case route of
        HomeRoute fragment ->
          let
            model = Home.init key apiAddress
            newPage = HomePage model
          in
          case page of
            HomePage _ ->
              case fragment of
                Just _ -> ( page, updateViewport fragment )
                Nothing -> ( newPage, updateViewport fragment )

            _ -> ( newPage, updateViewport fragment )

        VoteRoute pollId -> ( page, getVoteRequest apiAddress pollId )

        PollRoute pollId -> ( page, getPollRequest apiAddress pollId )

    Nothing -> ( ErrorPage, updateViewport Nothing )

updateViewport : Maybe String -> Cmd Msg
updateViewport fragment =
  case fragment of
    Just id ->
      -- https://discourse.elm-lang.org/t/is-it-possible-to-restore-the-browser-default-behavior-on-fragment-links-without-ports/3614/6
      Task.attempt ( \_ -> NoOp )
        ( Dom.getElement id
            -- Offset the height to account for navbar padding and content padding
            |> Task.andThen ( \info -> Dom.setViewport 0 ( info.element.y - 16 * 4 - 16 ) )
        )

    -- Set viewport to top of page if no fragment id is provided
    Nothing -> Task.attempt ( \_ -> NoOp ) ( Dom.setViewport 0 0 )

routeParser : Parser.Parser ( Route -> a ) a
routeParser =
  Parser.oneOf
    [ Parser.map HomeRoute ( Parser.fragment identity )
    , Parser.map VoteRoute ( Parser.s "vote" </> Parser.string )
    , Parser.map PollRoute ( Parser.s "poll" </> Parser.string )
    ]

getVoteRequest : String -> String -> Cmd Msg
getVoteRequest apiAddress pollId =
  Http.get
    { url = apiAddress ++ "/poll/" ++ pollId
    , expect = Http.expectJson GetVoteResponse getVoteDecoder
    }

getVoteDecoder : Decode.Decoder VoteResponse
getVoteDecoder =
  Decode.map5 VoteResponse
    ( Decode.at ["data", "title" ] Decode.string )
    ( Decode.at ["data", "choices" ] <| Decode.list Decode.string )
    ( Decode.at ["data", "poll_id" ] Decode.string )
    ( Decode.at ["data", "use_recaptcha" ] Decode.bool )
    ( Decode.at ["data", "created"] Iso8601.decoder )

getPollRequest : String -> String -> Cmd Msg
getPollRequest apiAddress pollId =
  Http.get
    { url = apiAddress ++ "/poll/" ++ pollId
    , expect = Http.expectJson GetPollResponse getPollDecoder
    }

getPollDecoder : Decode.Decoder PollResponse
getPollDecoder =
  Decode.map5 PollResponse
    ( Decode.at ["data", "title" ] Decode.string )
    ( Decode.at ["data", "winner"] Decode.string )
    ( Decode.at ["data", "tallies"] <| Decode.list <| Decode.keyValuePairs Decode.float )
    ( Decode.at ["data", "poll_id"] Decode.string )
    ( Decode.at ["data", "created"] Iso8601.decoder )



-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  case model.page of
    VotePage voteModel -> Sub.map VoteMsg <| Vote.subscriptions voteModel
    PollPage pageModel -> Sub.map PollMsg <| Poll.subscriptions pageModel
    _ -> Sub.none



-- UPDATE
type Msg
  = LoadTimezone Url.Url Zone
  | UrlRequested Browser.UrlRequest
  | UrlChanged Url.Url
  | HomeMsg Home.Msg
  | VoteMsg Vote.Msg
  | PollMsg Poll.Msg
  | GetVoteResponse ( Result Http.Error VoteResponse )
  | GetPollResponse ( Result Http.Error PollResponse )
  | NoOp

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    LoadTimezone url timezone ->
      let ( page, cmd ) = initPage model.page url model.key model.apiAddress
      in ( { model | page = page, timezone = timezone }, cmd )

    UrlRequested urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Navigation.pushUrl model.key <| Url.toString url )

        Browser.External href ->
          ( model, Navigation.load href )

    UrlChanged url ->
      let ( page, cmd ) = initPage model.page url model.key model.apiAddress
      in ( { model | page = page }, cmd)

    HomeMsg homeMsg ->
      case model.page of
        HomePage oldModel ->
          let ( newModel, cmd ) = Home.update homeMsg oldModel
          in ( { model | page = HomePage newModel }, Cmd.map HomeMsg cmd )
        _ -> ( model, Cmd.none )

    VoteMsg voteMsg ->
      case model.page of
        VotePage oldModel ->
          let ( newModel, cmd ) = Vote.update voteMsg oldModel
          in ( { model | page = VotePage newModel }, Cmd.map VoteMsg cmd )
        _ -> ( model, Cmd.none )

    PollMsg pollMsg ->
      case model.page of
        PollPage oldModel ->
          let ( newModel, cmd ) = Poll.update pollMsg oldModel
          in ( { model | page = PollPage newModel }, Cmd.map PollMsg cmd )
        _ -> ( model, Cmd.none )

    GetVoteResponse result ->
      case result of
        Ok response ->

          let ( voteModel, cmd ) = Vote.init model.key model.apiAddress response.title response.choices response.pollId response.useReCAPTCHA response.created model.timezone model.env Vote.Loaded
          in ( { model | page = VotePage voteModel }, Cmd.batch [ updateViewport Nothing, Cmd.map VoteMsg cmd ] )

        Err _ ->
          let ( voteModel, cmd ) = Vote.init model.key model.apiAddress "" [] "" False (Time.millisToPosix 0) Time.utc model.env Vote.Error
          in ( { model | page = VotePage voteModel }, Cmd.batch [ updateViewport Nothing, Cmd.map VoteMsg cmd ] )

    GetPollResponse result ->
      case result of
        Ok response ->
          let pollModel = Poll.init model.key model.apiAddress response.title response.winner response.tallies response.pollId response.created model.timezone Poll.Loaded
          in ( { model | page = PollPage pollModel }, updateViewport Nothing )

        Err _ ->
          let pollModel = Poll.init model.key model.apiAddress "" "" [] "" ( Time.millisToPosix 0 ) Time.utc Poll.Error
          in ( { model | page = PollPage pollModel }, updateViewport Nothing )

    NoOp -> ( model, Cmd.none )



-- VIEW
view : Model -> Browser.Document Msg
view model =
  let
    pageTitle =
      case model.page of
        HomePage _ ->
          "Functional Vote - Create a Ranked-Choice Poll"
        VotePage _ ->
          "Functional Vote - Vote in a Poll"
        PollPage _ ->
          "Functional Vote - View a Poll"
        ErrorPage ->
          "Functional Vote - Error"
        NoPage ->
          "Functional Vote"
  in
  { title = pageTitle
  , body = renderBody model
  }

renderBody : Model -> List (Html Msg)
renderBody model =
  [ div [ class "pt-16" ]
      -- Navbar needs to have a set z-value otherwise input placeholders and checkboxes appear over it
      [ div [ class "fixed w-full top-0 z-50 bg-blue-900 shadow-lg" ]
          [ div [ class "flex justify-between items-center max-w-screen-sm h-16 mx-auto px-4" ]
              [ a
                  [ class "fv-nav-btn"
                  , href "/"
                  ]
                  [ text "fv"
                  , div [ class "font-mono text-sm text-orange-500 opacity-25" ] [ text "=" ]
                  ]

              , div [ class "flex items-center justify-center" ]
                  [ div [ class "fv-code w-5 opacity-25" ] [ text "[" ]

                  , a
                      [ class "fv-nav-btn"
                      , href "https://github.com/maxrchung/FunctionalVote"
                      , target "_blank"
                      ]
                      [ Shared.renderIcon FeatherIcons.github ]

                  , div [ class "fv-code w-6 text-center opacity-25" ] [ text "," ]

                  , a
                      [ class "fv-nav-btn"
                      , href "https://twitter.com/FunctionalVote"
                      , target "_blank"
                      ]
                      [ Shared.renderIcon FeatherIcons.twitter ]

                  , div [ class "fv-code w-5 text-right opacity-25" ] [ text "]" ]
                  ]
              ]
          ]
        , let
            content =
              case model.page of
                HomePage homeModel ->
                  Html.map HomeMsg ( Home.view homeModel )
                VotePage voteModel ->
                  Html.map VoteMsg ( Vote.view voteModel )
                PollPage pollModel ->
                  Html.map PollMsg ( Poll.view pollModel )
                ErrorPage ->
                  Error.view
                NoPage ->
                  div [] []
          in div [ class "container max-w-screen-sm mx-auto p-4" ] [ content ]
      ]
  ]