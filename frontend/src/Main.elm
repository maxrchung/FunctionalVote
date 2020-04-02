module Main exposing ( .. )

import Browser
import Browser.Navigation as Navigation
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )
import Page.Home as Home
import Page.Vote as Vote
import Page.Poll as Poll
import Page.About as About
import Page.Error as Error
import Shared
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
  }

type Page
  = HomePage Home.Model
  | VotePage Vote.Model
  | PollPage Poll.Model
  | AboutPage
  | ErrorPage Error.Model

type Route 
  = HomeRoute
  | VoteRoute String
  | PollRoute String
  | AboutRoute

init : String -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init environment url key = 
  let 
    apiAddress = 
      if environment == "production" then
        "https://FunctionalVote.com:4001"
      else
        "http://localhost:4000"
    ( page, cmd ) = initPage url key apiAddress
  in ( Model key apiAddress page, cmd)

initPage : Url.Url -> Navigation.Key -> String -> ( Page, Cmd Msg )
initPage url key apiAddress =
  case Parser.parse routeParser url of
    Just route ->
      case route of
        HomeRoute ->
          let ( model, cmd ) = Home.init key apiAddress
          in ( HomePage model , Cmd.map HomeMsg cmd )

        VoteRoute pollId ->
          let ( model, cmd ) = Vote.init key pollId apiAddress
          in ( VotePage model, Cmd.map VoteMsg cmd )

        PollRoute pollId ->
          let ( model, cmd ) = Poll.init key pollId apiAddress
          in ( PollPage model, Cmd.map PollMsg cmd )

        AboutRoute ->
          ( AboutPage, Cmd.none )
    
    Nothing ->
      let ( model, cmd ) = Error.init key
      in ( ErrorPage model, Cmd.map ErrorMsg cmd )

routeParser : Parser.Parser ( Route -> a ) a
routeParser =
  Parser.oneOf
    [ Parser.map HomeRoute Parser.top
    , Parser.map VoteRoute ( Parser.s "vote" </> Parser.string )
    , Parser.map PollRoute ( Parser.s "poll" </> Parser.string )
    , Parser.map AboutRoute ( Parser.s "about" )
    ]



-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
  case model.page of
    VotePage voteModel ->
      Sub.map VoteMsg <| Vote.subscriptions voteModel
    PollPage pageModel ->
      Sub.map PollMsg <| Poll.subscriptions pageModel
    _ ->
      Sub.none



-- UPDATE
type Msg 
  = UrlRequested Browser.UrlRequest
  | UrlChanged Url.Url
  | HomeMsg Home.Msg
  | VoteMsg Vote.Msg
  | PollMsg Poll.Msg
  | ErrorMsg Error.Msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UrlRequested urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Navigation.pushUrl model.key <| Url.toString url )

        Browser.External href ->
          ( model, Navigation.load href )

    UrlChanged url ->
      let ( page, cmd ) = initPage url model.key model.apiAddress
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

    ErrorMsg errorMsg ->
      case model.page of
        ErrorPage oldModel -> 
          let ( newModel, cmd ) = Error.update errorMsg oldModel
          in ( { model | page = ErrorPage newModel }, Cmd.map ErrorMsg cmd )
        _ -> ( model, Cmd.none )



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
        ErrorPage _ ->
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
        ErrorPage errorModel ->
          [ Html.map ErrorMsg ( Error.view errorModel ) ]
  in
  [ div [ class "bg-blue-900 shadow-lg" ]
      [ div [ class "h-16 flex justify-between items-center max-w-screen-sm mx-auto px-4" ]
        [ a
            [ class "fv-nav-btn"
            , href "/"
            ]
            [ text "fv" 
            , div [ class "text-orange-500 font-mono opacity-25 text-sm" ] [ text "=" ]
            ]

        , div [ class "flex flex-row items-center justify-center" ]
          [ div [ class "fv-nav-code justify-start w-5" ]
              [ text "[" ]
            
          , a 
              [ class "fv-nav-btn"
              , href "/about"
              ]
              [ Shared.renderIcon FeatherIcons.helpCircle ]

          , div [ class "fv-nav-code justify-center w-6" ]
            [ text "," ]

          , a
              [ class "fv-nav-btn"
              , href "https://github.com/maxrchung/FunctionalVote"
              , target "_blank"
              ]
              [ Shared.renderIcon FeatherIcons.github ]

          , div [ class "fv-nav-code justify-center w-6" ]
            [ text "," ]

          , a
              [ class "fv-nav-btn"
              , href "https://twitter.com/FunctionalVote"
              , target "_blank"
              ]
              [ Shared.renderIcon FeatherIcons.twitter ]

          , div [ class "fv-nav-code justify-end w-5" ]
            [ text "]" ]
          ]
        ]
      ]
  , div [ class "container max-w-screen-sm mx-auto p-4" ] content
  ]