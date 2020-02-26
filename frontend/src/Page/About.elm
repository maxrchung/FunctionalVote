module Page.About exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)



-- VIEW
view : Html a
view =
  div [] 
    [ h1 [ class "fv-main-header" ]
      [ text "Why Functional Vote?" ]

    , div [ class "fv-main-text pb-4" ]
      [ text "-- Functional Vote was started by us ("
      , a [ href "https://github.com/maxrchung" ] [ text "Max" ]
      , text " and "
      , a [ href "https://github.com/Xenocidel" ] [ text "Aaron" ]
      , text " when we couldn’t easily find an online resource to make ranked-choice polls. We like working on software projects in our free time, so naturally, we tried to solve our own problem. We added a little educational twist, using only functional programming languages, and with Elm and Elixir in tow, we started Functional Vote."]

    , h2 [ class "fv-main-header" ]
      [ text "Why Ranked-Choice?"]

    , div [ class "fv-main-text pb-4" ]
      [ text "-- In traditional voting, voters can only vote for 1 out of many options. Ranked-choice voting, instead, allows voters to rank their options in order of preference. If a voter’s preferred 1st option loses, that voter’s 2nd choice is counted instead, and so forth." ]

    , div [ class "fv-main-text pb-4" ]
      [ text "-- Ranked-choice voting is objectively more fair than traditional voting because preferential ranking is much more flexible than a single vote cast in stone. Voters are incentivized to vote for their personal favorite option rather than try and vote for a popular choice that they think will win." ]

    , div [ class "fv-main-text" ]
      [ text "-- There are many resources online that explain ranked-choice in greater details. We particularly like CGP Grey's video on this topic since that's how we were first introduced to it:" ]

    ]