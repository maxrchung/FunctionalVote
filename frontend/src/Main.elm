module Main exposing (..)

import Browser
import Html exposing (..)
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Url
import Url.Parser as Parser exposing ((</>))
import Page.Home as Home
import Page.Vote as Vote
import Page.Poll as Poll
import Page.About as About
import Page.Error as Error



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
  | ErrorPage

type Route 
  = HomeRoute
  | VoteRoute Int
  | PollRoute Int
  | AboutRoute

init : () -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init _ url key = 
  let ( page, cmd ) = initPage url key
  in ( Model key page, cmd)

initPage : Url.Url -> Navigation.Key -> ( Page, Cmd Msg )
initPage url key =
  case Parser.parse routeParser url of
    Just route ->
      case route of
        HomeRoute ->
          let ( model, cmd ) = Home.init key
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
      ( ErrorPage, Cmd.none )

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
  | GoToGithub
  | GoToTwitter
  | GoToAbout
  | GoToHome

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
      let ( page, cmd ) = initPage url model.key
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

    GoToGithub ->
      ( model, Navigation.load "https://github.com/maxrchung/FunctionalVote" )

    GoToTwitter ->
      ( model, Navigation.load "https://twitter.com/FunctionalVote" )

    GoToAbout ->
      case model.page of
        AboutPage ->
          (model, Cmd.none)
        _ -> ( model, Navigation.pushUrl model.key "/about" )
      
    GoToHome ->
      case model.page of
        HomePage _ ->
          (model, Cmd.none)
        _ -> ( model, Navigation.pushUrl model.key "/" )



-- VIEW
view : Model -> Browser.Document Msg
view model =
  let 
    pageTitle =
      case model.page of
        HomePage _ -> 
          "Functional Vote - Create a Poll"
        VotePage _ ->
          "Functional Vote - Vote in a Poll"
        PollPage _ ->
          "Functional Vote - View a Poll"
        AboutPage ->
          "Functional Vote - About"
        ErrorPage ->
          "Functional Vote - Error" 
  in
  { title = pageTitle
  , body = renderBody model
  }
      
renderBody : Model -> List (Html Msg)
renderBody model =
  let 
    content =
      case model.page of
        HomePage homeModel -> 
          [ Html.map HomeMsg ( Home.view homeModel ) ]
        VotePage voteModel ->
          [ Html.map VoteMsg ( Vote.view voteModel ) ]
        PollPage pollModel ->
          [ Html.map PollMsg ( Poll.view pollModel ) ]
        AboutPage ->
          [ About.view ]
        ErrorPage ->
          [ Error.view ]
  in
  [ div [ class "bg-blue-900 shadow-lg" ]
      [ div [ class "h-16 flex justify-between items-center max-w-screen-sm mx-auto px-4" ]
        [ button
            [ class "fv-nav-btn"
            , onClick GoToHome
            ]
            [ text "v" 
            , div [ class "text-orange-500 font-mono text-sm pl-1"] [ text "=" ]
            ]

        , div [ class "flex flex-row items-center justify-center" ]
          [ div [ class "fv-nav-code justify-start w-5 " ]
              [ text "[" ]
            
          , button 
              [ class "fv-nav-btn"
              , onClick GoToAbout
              ]
              [ i [ class "fas fa-question" ] [] ]

          , div [ class "fv-nav-code justify-center w-6" ]
            [ text "," ]

          , button 
              [ class "fv-nav-btn"
              , onClick GoToGithub
              ]
              [ i [ class "fab fa-github" ] [] ]

          , div [ class "fv-nav-code justify-center w-6" ]
            [ text "," ]

          , button 
              [ class "fv-nav-btn"
              , onClick GoToTwitter
              ]
              [ i [ class "fab fa-twitter" ] [] ]

          , div [ class "fv-nav-code justify-end w-5" ]
            [ text "]" ]
          ]
        ]
      ]
  , div [ class "container max-w-screen-sm mx-auto p-4" ] content
  ]