module Inline exposing (..)

import Dict
import Html.Attributes exposing (type_)
import Json.Decode as Json
import Json.Encode exposing (encode)


elementsOrString : Json.Decoder String
elementsOrString =
    Json.oneOf
        [ Json.string
        , elements
        ]


elements : Json.Decoder String
elements =
    Json.lazy (\_ -> Json.list element)
        |> Json.map (String.join "")


fields : List String -> Json.Decoder String -> Json.Decoder String
fields ids decoder =
    ids
        |> List.map (\id -> Json.field id decoder)
        |> Json.oneOf


element : Json.Decoder String
element =
    [ Json.map2
        (++)
        ([ Json.string
         , fields [ "bold", "b" ] (Json.map (\s -> "__" ++ s ++ "__") elementsOrString)
         , Json.field "footnote" (Json.map (\s -> "[^" ++ s ++ "]") Json.string)
         , elementsOrString
            |> Json.field "effect"
            |> effect
            |> Json.map (\( def, body ) -> "{" ++ def ++ "}{" ++ body ++ "}")
         , input
         , fields [ "formula", "math" ] (Json.map (\s -> "$ " ++ s ++ " $") Json.string)
         , fields [ "italic", "i" ] (Json.map (\s -> "_" ++ s ++ "_") elementsOrString)
         , link
         , fields [ "strike", "s" ] (Json.map (\s -> "~" ++ s ++ "~") elementsOrString)
         , Json.field "string" Json.string
         , Json.field "symbol" Json.string
         , fields [ "superscript", "sup" ] (Json.map (\s -> "^" ++ s ++ "^") elementsOrString)
         , fields [ "underline", "u" ] (Json.map (\s -> "~~" ++ s ++ "~~") elementsOrString)
         , fields [ "code", "verbatim" ] (Json.map (\s -> "`" ++ s ++ "`") elementsOrString)
         ]
            |> Json.oneOf
        )
        toComment
    , script
    , html Nothing elementsOrString
    ]
        |> Json.oneOf


effect : Json.Decoder String -> Json.Decoder ( String, String )
effect decoder =
    Json.map5
        (\body begin end playback voice ->
            let
                steps =
                    case ( begin, end ) of
                        ( Just b, Nothing ) ->
                            Just b

                        ( Just b, Just e ) ->
                            Just (b ++ "-" ++ e)

                        _ ->
                            Nothing

                play =
                    case ( playback, voice ) of
                        ( Just True, Nothing ) ->
                            Just "!>"

                        ( Just True, Just v ) ->
                            Just ("!> " ++ v)

                        _ ->
                            Nothing
            in
            ( case ( steps, play ) of
                ( Just s, Nothing ) ->
                    s

                ( Nothing, Just p ) ->
                    p

                ( Just s, Just p ) ->
                    s ++ " " ++ p

                _ ->
                    ""
            , body
            )
        )
        decoder
        (Json.int
            |> Json.field "begin"
            |> Json.maybe
            |> Json.map (Maybe.map String.fromInt)
        )
        (Json.int
            |> Json.field "end"
            |> Json.maybe
            |> Json.map (Maybe.map String.fromInt)
        )
        (Json.bool
            |> Json.field "playback"
            |> Json.maybe
        )
        (Json.string
            |> Json.field "voice"
            |> Json.maybe
        )


toComment : Json.Decoder String
toComment =
    attributes
        |> Json.map
            (Maybe.map (\a -> "<!-- " ++ a ++ " -->")
                >> Maybe.withDefault ""
            )


attributes : Json.Decoder (Maybe String)
attributes =
    [ Json.string
    , [ Json.string
      , Json.map String.fromInt Json.int
      , Json.map String.fromFloat Json.float
      , Json.map
            (\b ->
                if b then
                    "true"

                else
                    "false"
            )
            Json.bool
      , Json.map (encode 0) Json.value
      ]
        |> Json.oneOf
        |> Json.dict
        |> Json.map
            (Dict.toList
                >> List.map (\( k, v ) -> "\"" ++ k ++ "\"=\"" ++ v ++ "\"")
                >> String.join " "
            )
    ]
        |> Json.oneOf
        |> Json.field "attributes"
        |> Json.maybe


{-| Reference decoder, required fields are link and url, alt and title are optional.
-}
link : Json.Decoder String
link =
    Json.map4 (\link_ alt_ url_ title_ -> link_ ++ "[" ++ alt_ ++ "](" ++ url_ ++ title_ ++ ")")
        (Json.field "link"
            (Json.string
                |> Json.andThen
                    (\t ->
                        case t of
                            "link" ->
                                Json.succeed ""

                            "image" ->
                                Json.succeed "!"

                            "audio" ->
                                Json.succeed "?"

                            "video" ->
                                Json.succeed "!?"

                            "embed" ->
                                Json.succeed "??"

                            _ ->
                                Json.fail "Only link, image, audio, video, and embed are supported"
                    )
            )
        )
        (Json.field "alt" elementsOrString
            |> Json.maybe
            |> Json.map (Maybe.withDefault "")
        )
        (Json.field "url" Json.string)
        (Json.field "title" elementsOrString
            |> Json.maybe
            |> Json.map (Maybe.map (\s -> " \"" ++ s ++ "\"") >> Maybe.withDefault "")
        )


script : Json.Decoder String
script =
    Json.map2
        (\s a ->
            "<script "
                ++ Maybe.withDefault "" a
                ++ ">\n"
                ++ s
                ++ "\n</ script>"
        )
        (Json.field "script" stringOrList)
        attributes


html : Maybe String -> Json.Decoder String -> Json.Decoder String
html separator decoder =
    Json.map3
        (\tag body attr ->
            "<"
                ++ tag
                ++ " "
                ++ Maybe.withDefault "" attr
                ++ ">"
                ++ Maybe.withDefault "" separator
                ++ body
                ++ Maybe.withDefault "" separator
                ++ "</"
                ++ tag
                ++ ">"
        )
        (Json.field "html" Json.string)
        (Json.field "body" decoder)
        attributes


input : Json.Decoder String
input =
    Json.field "input" Json.string
        |> Json.andThen
            (\type_ ->
                case type_ of
                    "text" ->
                        inputText
                            |> Json.map (\s -> "[[" ++ s ++ "]]")

                    "selection" ->
                        inputSelection
                            |> Json.map (\s -> "[[ " ++ s ++ " ]]")

                    _ ->
                        Json.fail "Only selection and text are supported input types"
            )


inputText : Json.Decoder String
inputText =
    Json.map2 Tuple.pair
        (Json.field "solution" Json.string)
        (Json.int
            |> Json.field "length"
            |> Json.maybe
        )
        |> Json.andThen
            (\( solution, length ) ->
                case length of
                    Nothing ->
                        Json.succeed solution

                    Just l ->
                        if l < String.length solution then
                            Json.fail "length must be greater than or equal to the length of the solution"

                        else
                            Json.succeed (solution ++ String.repeat l " ")
            )


inputSelection : Json.Decoder String
inputSelection =
    Json.map2
        (\options solution ->
            options
                |> List.indexedMap
                    (\i o ->
                        if List.member i solution then
                            "( " ++ o ++ " )"

                        else
                            o
                    )
                |> String.join " | "
        )
        inputOptions
        (Json.field "solution"
            (Json.oneOf
                [ Json.list Json.int
                , Json.map List.singleton Json.int
                ]
            )
        )


inputOptions : Json.Decoder (List String)
inputOptions =
    Json.field "options"
        (Json.list elementsOrString)


inputSolution : Json.Decoder (List Int)
inputSolution =
    Json.field "solution"
        (Json.oneOf
            [ Json.list Json.int
            , Json.map List.singleton Json.int
            ]
        )


stringOrList : Json.Decoder String
stringOrList =
    Json.oneOf
        [ Json.string
        , Json.string
            |> Json.list
            |> Json.map (String.join "\n")
        ]
