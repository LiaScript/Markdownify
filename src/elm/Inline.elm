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


elements : Decoder String
elements =
    oneOf
        [ string
        , field "type" string
            |> andThen typeOf
        , Json.Decode.lazy (\_ -> list elements)
            |> map (String.join " ")
        ]


body : Decoder String
body =
    field "body" elements


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
            string
                |> map (\key -> "[^" ++ key ++ "]")
                |> andThen addAttributes

        "html" ->
            html Nothing body

        "link" ->
            link

        "multimedia" ->
            multimedia

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
                            succeed (solution ++ String.repeat (l - String.length solution) " ")
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
        (field "solution" marked)


marked =
    [ int |> map List.singleton
    , list int
    , list bool
        |> map
            (List.indexedMap Tuple.pair
                >> List.filterMap
                    (\( i, b ) ->
                        if b then
                            Just i

                        else
                            Nothing
                    )
            )
    ]
        |> oneOf


inputOptions : Decoder (List String)
inputOptions =
    field "body" (list elements)


link : Decoder String
link =
    map3
        (\body_ url_ title_ ->
            if String.isEmpty body_ then
                url_

            else
                "[" ++ body_ ++ "](" ++ url_ ++ title_ ++ ")"
        )
        (field "body" elements
            |> maybe
            |> map (Maybe.withDefault "")
        )
        (field "url" string)
        (field "title" elements
            |> maybe
            |> map (Maybe.map (\s -> " \"" ++ s ++ "\"") >> Maybe.withDefault "")
        )
        |> andThen addAttributes


multimedia : Decoder String
multimedia =
    map4
        (\link_ alt_ url_ title_ ->
            if String.isEmpty link_ && String.isEmpty alt_ then
                url_

            else
                link_ ++ "[" ++ alt_ ++ "](" ++ url_ ++ title_ ++ ")"
        )
        (field "embedType"
            (string
                |> andThen
                    (\t ->
                        case t of
                            "image" ->
                                succeed "!"

                            "audio" ->
                                succeed "?"

                            "video" ->
                                succeed "!?"

                            "embed" ->
                                succeed "??"

                            _ ->
                                fail "Only image, audio, video, and embed are supported"
                    )
            )
        )
        (field "alt" elements
            |> maybe
            |> map (Maybe.withDefault "")
        )
        (field "url" string)
        (field "title" elements
            |> maybe
            |> map (Maybe.map (\s -> " \"" ++ s ++ "\"") >> Maybe.withDefault "")
        )
        |> andThen addAttributes


html : Maybe String -> Decoder String -> Decoder String
html separator decoder =
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
                >> List.map (\( k, v ) -> k ++ "=\"" ++ v ++ "\"")
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
