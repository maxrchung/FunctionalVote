module Vote exposing ( .. )

import Test exposing ( .. )
import Expect
import Dict
import Page.Vote as Vote



changeRank : Test
changeRank =
  describe "Change Rank"
    [ test "add 1 choice to ordered" <|
        \_ ->
          Vote.changeRank
            "1"
            "c1"
            Dict.empty
            [ "c1" ]
            |>
              Expect.equal
                ( Dict.fromList
                    [ ( 1, "c1" ) ]
                , []
                )

    , test "add all to ordered" <|
        \_ ->
          Vote.changeRank
            "2"
            "c2"
            ( Dict.fromList
                [ ( 1, "c1" ) ]
            )
            [ "c2" ]
            |>
              Expect.equal
                ( Dict.fromList
                    [ ( 1, "c1" )
                    , ( 2, "c2" )
                    ]
                , []
                )

    , test "ordered remove goes to unordered bottom" <|
      \_ ->
        Vote.changeRank
          "--"
          "c1"
          ( Dict.fromList
              [ ( 1, "c3" )
              , ( 2, "c1" )
              ]
          )
          [ "c2" ]
          |>
            Expect.equal
              ( Dict.fromList
                  [ ( 1, "c3" ) ]
              , [ "c2", "c1" ]
              )

    , test "bumps rank 1 choice to rank 2" <|
      \_ ->
        Vote.changeRank
          "1"
          "c2"
          ( Dict.fromList
            [ ( 1, "c1" ) ]
          )
          [ "c2" ]
          |>
            Expect.equal
              ( Dict.fromList
                  [ ( 1, "c2" )
                  , ( 2, "c1" )
                  ]
              , []
              )

    , test "bumps last choice to unordered" <|
      \_ ->
        Vote.changeRank
          "2"
          "c1"
          ( Dict.fromList
              [ ( 1, "c1" )
              , ( 2, "c2" )
              ]
          )
          []
          |>
            Expect.equal
              ( Dict.fromList
                  [ ( 2, "c1" ) ]
              , [ "c2" ]
              )

    , test "bumps unfilled space and stops" <|
      \_ ->
        Vote.changeRank
          "1"
          "c1"
          ( Dict.fromList
              [ ( 1, "c2" )
              , ( 3, "c3" )
              ]
          )
          [ "c1" ]
          |>
            Expect.equal
              ( Dict.fromList
                  [ ( 1, "c1" )
                  , ( 2, "c2" )
                  , ( 3, "c3" )
                  ]
              , []
              )

    , test "bumps multiple unfilled spaces and stops" <|
      \_ ->
        Vote.changeRank
          "1"
          "c1"
          ( Dict.fromList
              [ ( 1, "c2" )
              , ( 4, "c4" )
              ]
          )
          [ "c1", "c5", "c6" ]
          |>
            Expect.equal
              ( Dict.fromList
                  [ ( 1, "c1" )
                  , ( 2, "c2" )
                  , ( 4, "c4" )
                  ]
              , [ "c5", "c6" ]
              )
    ]

rankValue : Test
rankValue =
  describe "Rank Value"
    [ test "1 -> 1st" <|
        \_ -> Vote.rankValue 1 |> Expect.equal "1st"

    , test "2 -> 2nd" <|
        \_ -> Vote.rankValue 2 |> Expect.equal "2nd"

    , test "3 -> 3rd" <|
        \_ -> Vote.rankValue 3 |> Expect.equal "3rd"

    , test "4 -> 4th" <|
        \_ -> Vote.rankValue 4 |> Expect.equal "4th"

    , test "11 -> 11th" <|
        \_ -> Vote.rankValue 11 |> Expect.equal "11th"

    , test "12 -> 12th" <|
        \_ -> Vote.rankValue 12 |> Expect.equal "12th"

    , test "13 -> 13th" <|
        \_ -> Vote.rankValue 13 |> Expect.equal "13th"

    , test "14 -> 14th" <|
        \_ -> Vote.rankValue 14 |> Expect.equal "14th"

    , test "21 -> 21st" <|
        \_ -> Vote.rankValue 21 |> Expect.equal "21st"

    , test "100 -> 100th" <|
        \_ -> Vote.rankValue 100 |> Expect.equal "100th"

    , test "102 -> 102nd" <|
        \_ -> Vote.rankValue 102 |> Expect.equal "102nd"

    , test "112 -> 112th" <|
        \_ -> Vote.rankValue 112 |> Expect.equal "112th"
    ]