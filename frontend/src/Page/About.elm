module Page.About exposing ( .. )

import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Html.Events exposing ( .. )



-- VIEW
view : Html a
view =
  div [] 
    [ div [ class "fv-code" ] [ text "{-" ]
      
    , h1 [ class "fv-header" ]
      [ text "Why Functional Vote?" ]

    , div [ class "fv-text" ]
      [ text "Functional Vote was started by us ("
      , a [ href "https://github.com/maxrchung"
          , target "_blank" ] [ text "Max" ]
      , text " and "
      , a [ href "https://github.com/Xenocidel"
          , target "_blank" ] [ text "Aaron" ]
      , text ") when we couldn’t easily find an online resource to make ranked-choice polls. We like working on software projects in our free time, so naturally, we tried to solve our own problem. We added a little educational twist, using only functional programming languages, and with Elm and Elixir in tow, we began Functional Vote."]

    , div
      [ class "fv-break" ] 
      [ text "--" ]

    , h2 [ class "fv-header" ]
      [ text "Why Ranked-Choice?"]

    , div [ class "fv-text mb-6" ]
      [ text "With traditional voting, voters only vote for one out of many options. Ranked-choice voting, instead, allows voters to rank their options in order of preference. If a voter’s preferred first option loses, that voter’s second choice is counted instead, then third, and so forth." ]

    , div [ class "fv-text mb-6" ]
      [ text "Ranked-choice voting is more fair than traditional voting because preferential ranking is much more flexible than a single vote cast in stone. Voters are incentivized to vote for their personal favorite options rather than try and vote for a popular choice that they think will win." ]

    , div [ class "fv-text mb-6" ]
      [ text "There are many resources online that explain ranked-choice in greater details. We particularly like CGP Grey's video on this topic since that's how we were first introduced to the concept:" ]

    , div [ class "embed-responsive embed-responsive-16by9"]
      [ iframe 
        [ class "embed-responsive-item"
        , src "https://www.youtube.com/embed/3Y3jE3B8HsE"
        , attribute "frameborder" "none"
        , attribute "allow" "accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
        , attribute "allowfullscreen" "true"
        ] []
      ]

    , div [ class "fv-code mt-2" ] [ text "-}" ]
    ]