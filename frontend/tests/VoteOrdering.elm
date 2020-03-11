module VoteOrdering exposing ( .. )

import Test exposing ( .. )
import Expect
import Dict
import Set
import Page.Vote exposing ( changeRank )



voteOrdering : Test
voteOrdering =
  describe "Vote Ordering"
    [ test "add 1 choice to ordered" <|
        \_ ->
            changeRank "1" "c1" Dict.empty ( Set.fromList ["c1"] )
              |> Expect.equal ( Dict.fromList [ ( 1, "c1" ) ], Set.empty )

    , test "add all to ordered" <|
        \_ ->
            changeRank "2" "c2" 
              ( Dict.fromList 
                  [ ( 1, "c1" ) ] 
              )
              ( Set.fromList 
                  [ "c2" ] 
              )
              |> Expect.equal 
                  ( Dict.fromList 
                      [ ( 1, "c1" )
                      , ( 2, "c2" ) 
                      ]
                  , Set.empty 
                  )
    ]