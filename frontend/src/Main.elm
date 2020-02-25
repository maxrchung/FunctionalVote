module Main exposing (..)

import Browser
import Html exposing (..)
import Browser.Navigation as Navigation
import Url
import Url.Parser as Parser exposing ((</>))
import Page.Home as Home
import Page.Vote as Vote
import Page.Poll as Poll
import Page.About as About



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
  | AboutPage
  | BadPage

type Route 
  = HomeRoute
  | VoteRoute Int
  | PollRoute Int
  | AboutRoute

init : () -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key = 
  let ( page, cmd ) = initPage url
  in ( Model key page, cmd)

initPage : Url.Url -> ( Page, Cmd Msg )
initPage url =
  case Parser.parse routeParser url of
    Just route ->
      case route of
        HomeRoute ->
          let ( model, cmd ) = Home.init
          in ( HomePage model , Cmd.map HomeMsg cmd )

        VoteRoute pollId ->
          let ( model, cmd ) = Vote.init pollId
          in ( VotePage model, Cmd.map VoteMsg cmd )

        PollRoute pollId ->
          let ( model, cmd ) = Poll.init pollId
          in ( PollPage model, Cmd.map PollMsg cmd )

        AboutRoute ->
          ( AboutPage, Cmd.none )
    
    Nothing ->
      ( BadPage, Cmd.none )

routeParser : Parser.Parser ( Route -> a ) a
routeParser =
  Parser.oneOf
    [ Parser.map HomeRoute Parser.top
    , Parser.map VoteRoute ( Parser.s "vote" </> Parser.int )
    , Parser.map PollRoute ( Parser.s "poll" </> Parser.int )
    , Parser.map AboutRoute ( Parser.s "about" )
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
      let ( page, cmd ) = initPage url
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



-- VIEW
view : Model -> Browser.Document Msg
view model =
  case model.page of
    HomePage homeModel -> 
      { title = "Functional Vote - Create a Poll"
      , body = [ Html.map HomeMsg ( Home.view homeModel ) ]
      }
    VotePage voteModel ->
      { title = "Functional Vote - Vote in a Poll"
      , body = [ Html.map VoteMsg ( Vote.view voteModel ) ]
      }
    PollPage pollModel ->
      { title = "Functional Vote - View a Poll"
      , body = [ Html.map PollMsg ( Poll.view pollModel ) ]
      }
    AboutPage ->
      { title = "Functional Vote - About"
      , body = [ About.view ]
      }
    BadPage ->
      { title = "Functional Vote - Error" 
      , body = [ text "Invalid URL!!!" ]
      }