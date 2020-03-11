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
            changeRank "1" "c1" Dict.empty [ "c1" ]
              |> Expect.equal ( Dict.fromList [ ( 1, "c1" ) ], [] )

    , test "add all to ordered" <|
        \_ ->
            changeRank "2" "c2" 
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
            changeRank "--" "c1" 
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
    ]