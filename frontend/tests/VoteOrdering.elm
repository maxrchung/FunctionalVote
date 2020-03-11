module VoteOrdering exposing ( .. )

import Test exposing ( .. )
import Expect
import Dict
import Page.Vote exposing ( changeRank )



voteOrdering : Test
voteOrdering =
  describe "Vote Ordering"
    [ test "add 1 choice to ordered" <|
        \_ ->
            changeRank 
              "1" 
              "c1" 
              Dict.empty 
                [ "c1" ]
              |> Expect.equal 
                ( Dict.fromList 
                    [ 
                      ( 1, "c1" ) 
                    ]
                , [] 
                )

    , test "add all to ordered" <|
        \_ ->
            changeRank 
              "2" 
              "c2" 
              ( Dict.fromList 
                  [ ( 1, "c1" ) ] 
              )
              [ "c2" ] 
              |> Expect.equal 
                  ( Dict.fromList 
                      [ ( 1, "c1" )
                      , ( 2, "c2" )
                      ]
                  , []
                  )

    , test "ordered remove goes to unordered bottom" <|
      \_ ->
          changeRank 
            "--" 
            "c1" 
            ( Dict.fromList 
                [ ( 1, "c3" ) 
                , ( 2, "c1" )
                ]
                
            )
            [ "c2" ] 
            |> Expect.equal 
                ( Dict.fromList 
                    [ ( 1, "c3" ) ]
                , [ "c2", "c1" ] 
                )

    , test "bumps rank 1 choice to rank 2" <|
      \_ ->
          changeRank 
            "1" 
            "c2" 
            ( Dict.fromList 
                [ ( 1, "c1" ) ]
            )
            [ "c2" ] 
            |> Expect.equal 
                ( Dict.fromList 
                    [ ( 1, "c2" ) 
                    , ( 2, "c1" ) 
                    ]
                , [] 
                )
    
    , test "bumps last choice to unordered" <|
      \_ ->
          changeRank 
            "2" 
            "c1" 
            ( Dict.fromList 
                [ ( 1, "c1" )
                , ( 2, "c2" )
                ]
            )
            [] 
            |> Expect.equal 
                ( Dict.fromList 
                    [ ( 2, "c1" ) ]
                , [ "c2" ] 
                )

    , test "bumps unfilled space and stops" <|
      \_ ->
          changeRank 
            "1" 
            "c1" 
            ( Dict.fromList 
                [ ( 1, "c2" )
                , ( 3, "c3" )
                ]
            )
            [ "c1" ] 
            |> Expect.equal 
                ( Dict.fromList 
                    [ ( 1, "c1" )
                    , ( 2, "c2" ) 
                    , ( 3, "c3" )
                    ]
                , [] 
                )
    
    , test "bumps multiple unfilled spaces and stops" <|
      \_ ->
          changeRank 
            "1" 
            "c1" 
            ( Dict.fromList 
                [ ( 1, "c2" )
                , ( 4, "c4" )
                ]
            )
            [ "c1", "c5", "c6" ] 
            |> Expect.equal 
                ( Dict.fromList 
                    [ ( 1, "c1" )
                    , ( 2, "c2" ) 
                    , ( 4, "c4" )
                    ]
                , [ "c5", "c6" ] 
                )
    ]