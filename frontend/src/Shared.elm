
module Shared exposing ( .. )

import DateFormat
import FeatherIcons
import Html exposing ( .. )
import Html.Attributes exposing ( .. )
import Time exposing ( Posix, Zone )

toHumanTimeString : Posix -> Zone -> String
toHumanTimeString time timezone =
  DateFormat.format
    [ DateFormat.monthNameAbbreviated
    , DateFormat.text " "
    , DateFormat.dayOfMonthNumber
    , DateFormat.text ", "
    , DateFormat.yearNumber
    , DateFormat.text " "
    , DateFormat.hourNumber
    , DateFormat.text ":"
    , DateFormat.minuteNumber
    , DateFormat.text " "
    , DateFormat.amPmUppercase
    ]
    timezone
    time

renderShareLinks : String -> String -> String -> String -> Html a
renderShareLinks url helpText title message =
  let
    twitterUrl = "https://twitter.com/intent/tweet?text=" ++ message ++ title ++ "&via=FunctionalVote&url=" ++ url
    facebookUrl = "https://www.facebook.com/sharer/sharer.php?u=" ++ url
    mailUrl = "mailto:?subject=Functional Vote - " ++ title ++ "&body=" ++ message ++ url
  in

  div []
    [ div [ class "fv-break" ] [ text "--" ]

    , div [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "--" ]
        , p [ class "fv-text w-full" ] [ text helpText ]
        , div [ class "w-8" ] []
        ]


    , div [ class "flex justify-between" ]
        [ div [ class "fv-code opacity-25" ] [ text "links" ]
        , div [ class "fv-code" ] [ text "=" ]
        ]

    , div
        [ class "flex justify-between items-center" ]
        [ div [ class "w-8 fv-code" ] [ text "[" ]

        , div
            [ class "w-full" ]
            [ div
                [ class "flex justify-between items-center" ]
                [ div [ class "text-blue-500" ] [ renderIcon FeatherIcons.link ]

                , div
                    [ class "mx-2 w-full my-2"
                    , id "fv-share-link" ]
                    [ input
                        [ class "fv-share-link fv-input"
                        , readonly True
                        , value <| url
                        ]
                        []
                    ]

                , button
                    [ class "fv-nav-btn fv-nav-btn-orange fv-share-copy"
                    , attribute "data-clipboard-target" ".fv-share-link"
                    ]
                    [ renderIcon FeatherIcons.copy ]
                ]
            ]

        , div [ class "w-8" ] []
        ]

    , div
        [ class "fv-share-text flex justify-between items-center hidden" ]
        [ div [ class "fv-code w-8" ] [ text "--" ]

        , div
            [ class "w-full flex justify-between items-center -mt-1" ]
            [ div [ class "invisible" ] [ renderIcon FeatherIcons.link ]

            , div [ class "mx-2 w-full text-orange-500" ] [ text "Link copied" ]

            , div [ class "w-10 mx-2" ] []
            ]
        , div [ class "w-8" ] []
        ]

    , div
        [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "," ]
        , div
            [ class "w-full flex justify-between items-center my-2" ]
            [ div [ class "text-blue-500" ] [ renderIcon FeatherIcons.twitter ]

            , div
                [ class "mx-2 w-full" ]
                [ input
                    [ class "fv-input"
                    , readonly True
                    , value twitterUrl
                    ]
                    []
                ]

            , a
                [ class "fv-nav-btn fv-nav-btn-orange"
                , href <| twitterUrl
                , target "_blank"
                ]
                [ renderIcon FeatherIcons.share ]
            ]
        , div [ class "w-8" ] []
        ]

    , div
        [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "," ]

        , div
            [ class "w-full flex justify-between items-center my-2" ]
            [ div [ class "text-blue-500" ] [ renderIcon FeatherIcons.facebook ]

            , div
                [ class "mx-2 w-full" ]
                [ input
                    [ class "fv-input"
                    , readonly True
                    , value <| facebookUrl
                    ]
                    []
                ]

            , a
                [ class "fv-nav-btn fv-nav-btn-orange"
                , href facebookUrl
                , target "_blank"
                ]
                [ renderIcon FeatherIcons.share ]
            ]
        , div [ class "w-8" ] []
        ]

    , div
        [ class "flex justify-between items-center" ]
        [ div [ class "fv-code w-8" ] [ text "," ]

        , div
            [ class "w-full flex justify-between items-center my-2" ]
            [ div [ class "text-blue-500" ] [ renderIcon FeatherIcons.mail ]

            , div
                [ class "mx-2 w-full" ]
                [ input
                    [ class "fv-input"
                    , readonly True
                    , value <| mailUrl
                    ]
                    []
                ]

            , a
                [ class "fv-nav-btn fv-nav-btn-orange"
                , href mailUrl
                , target "_blank"
                ]
                [ renderIcon FeatherIcons.share ]
            ]
        , div [ class "w-8" ] []
        ]

    , div [ class "fv-code" ] [ text "]" ]
    ]

renderIcon : FeatherIcons.Icon -> Html a
renderIcon icon =
  icon
    |> FeatherIcons.withSize 22
    |> FeatherIcons.toHtml []