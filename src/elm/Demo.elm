module Demo exposing (..)

import Browser
import Example as Example
import Html exposing (Html, div, textarea)
import Html.Attributes exposing (height, style, value)
import Html.Events exposing (onInput)
import Json.Decode
import Json.Encode
import Markdownify exposing (markdownify)


type alias Model =
    { input : String
    , output : Result String String
    }


type Msg
    = Input String


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "justify-content" "space-between"
        , style "width" "calc(100vw - 20px)"
        , style "height" "97.0vh"
        ]
        [ textarea
            [ onInput Input
            , value model.input
            , style "width" "49.5%"
            , style "height" "100%"
            ]
            []
        , div
            [ style "width" "49.5%"
            , style "white-space" "pre"
            , style "height" "100%"
            ]
            [ case model.output of
                Ok output ->
                    Html.node "textarea"
                        [ Html.Attributes.attribute "value" output
                        , style "width" "100%"
                        , style "height" "100%"
                        ]
                        [ Html.text output ]

                Err message ->
                    Html.div
                        [ style "color" "red"
                        , style "width" "100%"
                        , style "height" "100%"
                        , style "white-space" "pre-wrap"
                        , style "overflow-wrap" "anywhere"
                        , style "border" "1px solid #000"
                        , style "overflow" "auto"
                        , style "padding" "3px"
                        ]
                        [ Html.text message ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input input ->
            ( { model
                | input = parse input
                , output = markdownify input
              }
            , Cmd.none
            )


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : String -> ( Model, Cmd Msg )
init json =
    let
        input =
            if String.isEmpty json then
                Example.json

            else
                json
    in
    ( { input = parse input
      , output = markdownify input
      }
    , Cmd.none
    )


parse : String -> String
parse input =
    case Json.Decode.decodeString Json.Decode.value input of
        Ok json ->
            Json.Encode.encode 2 json

        _ ->
            input
