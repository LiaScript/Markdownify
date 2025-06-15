module Inline exposing (..)

import Dict
import Json.Decode
    exposing
        ( Decoder
        , andThen
        , bool
        , dict
        , fail
        , field
        , float
        , int
        , list
        , map
        , map2
        , map3
        , map4
        , map5
        , maybe
        , oneOf
        , string
        , succeed
        , value
        )
import Json.Encode exposing (encode)



{-

   { "type": "bold"
   , "body": ...
   , "attr": ...
   }
-}


elementOrString : Decoder String
elementOrString =
    oneOf [ element, string ]


elementsOrString : Decoder String
elementsOrString =
    oneOf
        [ list element |> map (String.join " ")
        , elementOrString
        ]


element : Decoder String
element =
    field "type" string
        |> andThen typeOf


body : Decoder String
body =
    [ element
    , list element |> map (String.join "\n")
    , stringOrList
    ]
        |> oneOf
        |> field "body"


typeOf : String -> Decoder String
typeOf id =
    case id of
        "bold" ->
            body
                |> map (\b -> "__" ++ b ++ "__")
                |> andThen addAttributes

        "italic" ->
            body
                |> map (\b -> "_" ++ b ++ "_")
                |> andThen addAttributes

        "formula" ->
            body
                |> map (\s -> "$ " ++ s ++ " $")
                |> andThen addAttributes

        "symbol" ->
            field "body" string
                |> andThen addAttributes

        "string" ->
            field "body" string
                |> andThen addAttributes

        "strike" ->
            body
                |> map (\s -> "~" ++ s ++ "~")
                |> andThen addAttributes

        "sup" ->
            body
                |> map (\s -> "^" ++ s ++ "^")
                |> andThen addAttributes

        "underline" ->
            body
                |> map (\s -> "~~" ++ s ++ "~~")
                |> andThen addAttributes

        "code" ->
            field "body" string
                |> map (\s -> "`" ++ s ++ "`")
                |> andThen addAttributes

        "effect" ->
            effect body
                |> map (\( conf, s ) -> "{" ++ conf ++ "}{" ++ s ++ "}")
                |> andThen addAttributes

        "footnote" ->
            body
                |> map (\s -> "[^" ++ s ++ "]")
                |> andThen addAttributes

        "html" ->
            html__ Nothing body

        "link" ->
            link False

        "script" ->
            map2
                (\s a ->
                    "<script "
                        ++ Maybe.withDefault "" a
                        ++ ">"
                        ++ s
                        ++ "</script>"
                )
                (field "body" stringOrList)
                attributes

        "input" ->
            inputText
                |> map (\s -> "[[" ++ s ++ "]]")
                |> andThen addAttributes

        "select" ->
            inputSelection
                |> map (\s -> "[[ " ++ s ++ " ]]")
                |> andThen addAttributes

        _ ->
            fail <| "unknown inline type " ++ id


input : Decoder String
input =
    field "inputType" string
        |> andThen
            (\type_ ->
                case type_ of
                    "text" ->
                        inputText
                            |> map (\s -> "[[" ++ s ++ "]]")

                    "selection" ->
                        inputSelection
                            |> map (\s -> "[[ " ++ s ++ " ]]")

                    _ ->
                        fail "Only selection and text are supported input types"
            )


voice_ : Decoder (Maybe String)
voice_ =
    string
        |> field "voice"
        |> maybe


playback_ : Decoder Bool
playback_ =
    bool
        |> field "playback"
        |> maybe
        |> map (Maybe.withDefault False)


start_ : Decoder (Maybe String)
start_ =
    int
        |> field "start"
        |> maybe
        |> map (Maybe.map String.fromInt)


stop_ : Decoder (Maybe String)
stop_ =
    int
        |> field "stop"
        |> maybe
        |> map (Maybe.map String.fromInt)


inputText : Decoder String
inputText =
    map2 Tuple.pair
        (field "solution" string)
        (int
            |> field "length"
            |> maybe
        )
        |> andThen
            (\( solution, length ) ->
                case length of
                    Nothing ->
                        succeed solution

                    Just l ->
                        if l < String.length solution then
                            fail "length must be greater than or equal to the length of the solution"

                        else
                            succeed (solution ++ String.repeat l " ")
            )


inputSelection : Decoder String
inputSelection =
    map2
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
        (field "solution"
            (oneOf
                [ list int
                , map List.singleton int
                ]
            )
        )


inputOptions : Decoder (List String)
inputOptions =
    field "body" (list elementsOrString)


link : Bool -> Decoder String
link multimedia =
    map4 (\link_ alt_ url_ title_ -> link_ ++ "[" ++ alt_ ++ "](" ++ url_ ++ title_ ++ ")")
        (field "linkType"
            (string
                |> andThen
                    (\t ->
                        case t of
                            "link" ->
                                if multimedia then
                                    fail "in this context only multimedia links are supported"

                                else
                                    succeed ""

                            "image" ->
                                succeed "!"

                            "audio" ->
                                succeed "?"

                            "video" ->
                                succeed "!?"

                            "embed" ->
                                succeed "??"

                            _ ->
                                fail "Only link, image, audio, video, and embed are supported"
                    )
            )
        )
        (field "alt" body
            |> maybe
            |> map (Maybe.withDefault "")
        )
        (field "url" string)
        (field "title" body
            |> maybe
            |> map (Maybe.map (\s -> " \"" ++ s ++ "\"") >> Maybe.withDefault "")
        )
        |> andThen addAttributes


html__ : Maybe String -> Decoder String -> Decoder String
html__ separator decoder =
    map3
        (\tag body_ attr ->
            "<"
                ++ tag
                ++ " "
                ++ Maybe.withDefault "" attr
                ++ ">"
                ++ Maybe.withDefault "" separator
                ++ body_
                ++ Maybe.withDefault "" separator
                ++ "</"
                ++ tag
                ++ ">"
        )
        (field "htmlTag" string)
        decoder
        attributes


effect : Decoder String -> Decoder ( String, String )
effect decoder =
    map5
        (\body_ begin end playback voice ->
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
                        ( True, Nothing ) ->
                            Just "!>"

                        ( True, Just v ) ->
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
            , body_
            )
        )
        decoder
        start_
        stop_
        playback_
        voice_


toComment : Decoder String
toComment =
    attributes
        |> map
            (Maybe.map (\a -> "<!-- " ++ a ++ " -->")
                >> Maybe.withDefault ""
            )


addAttributes : String -> Decoder String
addAttributes inline =
    map (\a -> inline ++ a) toComment


attributes : Decoder (Maybe String)
attributes =
    [ string
    , [ string
      , map String.fromInt int
      , map String.fromFloat float
      , map
            (\b ->
                if b then
                    "true"

                else
                    "false"
            )
            bool
      , map (encode 0) value
      ]
        |> oneOf
        |> dict
        |> map
            (Dict.toList
                >> List.map (\( k, v ) -> "\"" ++ k ++ "\"=\"" ++ v ++ "\"")
                >> String.join " "
            )
    ]
        |> oneOf
        |> field "attr"
        |> maybe


stringOrList : Decoder String
stringOrList =
    oneOf
        [ string
        , string
            |> list
            |> map (String.join "\n")
        ]
