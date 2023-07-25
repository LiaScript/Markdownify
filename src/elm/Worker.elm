port module Worker exposing (Model, main)

import Demo exposing (Msg(..))
import Markdownify exposing (markdownify)
import Platform


port outPort : ( Bool, String ) -> Cmd msg


port inPort : (String -> msg) -> Sub msg


type alias Model =
    { input : String
    , output : Result String String
    }


type Msg
    = Input String


main : Program String Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : String -> ( Model, Cmd Msg )
init =
    parse


update : Msg -> Model -> ( Model, Cmd Msg )
update msg _ =
    case msg of
        Input input ->
            parse input


parse : String -> ( Model, Cmd Msg )
parse input =
    let
        output =
            markdownify input
    in
    ( { input = input
      , output = output
      }
    , case output of
        Ok liascript ->
            outPort ( True, liascript )

        Err info ->
            outPort ( False, info )
    )
