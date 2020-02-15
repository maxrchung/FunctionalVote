module Main exposing (..)

import Browser
import Html exposing (..)
import Array exposing (..)
import Browser.Navigation as Navigation
import Url
import Url.Parser as Parser exposing ((</>))
import Page.Home as Home
import Page.Vote as Vote
import Page.Poll as Poll



-- MAIN
main = 
  Browser.application 
    { init = init
    , update = update
    , subscriptions = \_ -> Sub.none
    , view = view
    , onUrlRequest = UrlRequested
    , onUrlChange = UrlChanged
    }



-- MODEL
type alias Model = 
  { key: Navigation.Key
  , page : Page
  }

type Page
  = HomePage Home.Model
  | VotePage Vote.Model
  | PollPage Poll.Model
  | BadPage

type Route 
  = HomeRoute
  | VoteRoute String
  | PollRoute String

init : () -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key = 
  ( Model key (initPage url), Cmd.none )

initPage : Url.Url -> Page
initPage url =
  case Parser.parse routeParser url of
    Just routeToPage ->
      case routeToPage of
        HomeRoute ->
          HomePage (Home.Model "" (Array.fromList ["", "", ""]))

        VoteRoute pollId ->
          VotePage (Vote.Model pollId)

        PollRoute pollId ->
          PollPage (Poll.Model pollId)
    
    Nothing ->
      BadPage

routeParser : Parser.Parser (Route -> a) a
routeParser =
  Parser.oneOf
    [ Parser.map HomeRoute Parser.top
    , Parser.map VoteRoute (Parser.s "vote" </> Parser.string)
    , Parser.map PollRoute (Parser.s "poll" </> Parser.string)
    ]



-- UPDATE
type Msg 
  = UrlRequested Browser.UrlRequest
  | UrlChanged Url.Url
  | HomeMsg Home.Msg
  | VoteMsg Vote.Msg
  | PollMsg Poll.Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UrlRequested urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Navigation.pushUrl model.key (Url.toString url) )

        Browser.External href ->
          ( model, Navigation.load href )

    UrlChanged url ->
      ( { model | page = initPage url }, Cmd.none )

    HomeMsg homeMsg ->
      case model.page of
        HomePage oldModel -> 
          let 
            (newModel, cmds) = Home.update homeMsg oldModel
          in
          ( { model | page = HomePage newModel }
          , Cmd.map HomeMsg cmds
          )
        _ -> ( model, Cmd.none )
      
    VoteMsg voteMsg ->
      case model.page of
        VotePage oldModel -> 
          let 
            (newModel, cmds) = Vote.update voteMsg oldModel
          in
          ( { model | page = VotePage newModel }
          , Cmd.map VoteMsg cmds
          )
        _ -> ( model, Cmd.none )

    PollMsg pollMsg ->
      case model.page of
        PollPage oldModel -> 
          let 
            (newModel, cmds) = Poll.update pollMsg oldModel
          in
          ( { model | page = PollPage newModel }
          , Cmd.map PollMsg cmds
          )
        _ -> ( model, Cmd.none )



-- VIEW
view : Model -> Browser.Document Msg
view model =
  case model.page of
    HomePage homeModel -> 
      { title = "Functional Vote - Create a Poll"
      , body = [
          Html.map HomeMsg (Home.view homeModel)
        ]
      }
    VotePage voteModel ->
      { title = "Functional Vote - Vote in a Poll"
      , body = [
          Html.map VoteMsg (Vote.view voteModel)
        ]
      }
    PollPage pollModel ->
      { title = "Functional Vote - View a Poll"
      , body = [
          Html.map PollMsg (Poll.view pollModel)
        ]
      }
    BadPage ->
      { title = "Functional Vote - Error" 
      , body = 
            [ text "Invalid URL!!!" ]
      }