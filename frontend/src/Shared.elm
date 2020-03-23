
module Shared exposing ( .. )

import Html exposing ( .. )
import Html.Attributes exposing ( .. )

renderShareLinks : String -> Html a
renderShareLinks url =
    div [] [ text url ]