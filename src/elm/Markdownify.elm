module Markdownify exposing (markdownify)

import Block
import Dict
import Inline
import Json.Decode as Json


markdownify : String -> Result String String
markdownify =
    Json.decodeString liascript
        >> Result.mapError Json.errorToString


liascript : Json.Decoder String
liascript =
    Json.map2 (\m s -> m ++ s)
        (meta True)
        sections


sections : Json.Decoder String
sections =
    Json.list section
        |> Json.field "sections"
        |> Json.map (String.join "\n\n\n")


body : Json.Decoder String
body =
    [ Block.elementOrString
    , [ Block.elementOrString
      ]
        |> Json.oneOf
        |> Json.list
        |> Json.map (String.join "\n\n")
    ]
        |> Json.oneOf
        |> Json.field "body"


section : Json.Decoder String
section =
    Json.map3 (\t b m -> t ++ m ++ "\n\n" ++ b)
        title
        body
        (meta False)


title : Json.Decoder String
title =
    Json.map2 (\i t -> i ++ " " ++ t)
        indentation
        (Json.field "title" Inline.elements)


indentation : Json.Decoder String
indentation =
    Json.field "indent" Json.int
        |> Json.andThen
            (\i ->
                if i > 0 && i < 7 then
                    Json.succeed (String.repeat i "#")

                else
                    Json.fail "Indentation must be between 1 and 6"
            )


meta : Bool -> Json.Decoder String
meta large =
    Json.field "meta"
        (Json.oneOf
            [ Json.string |> Json.map (Tuple.pair True)
            , Json.list Json.string |> Json.map (String.join "\n" >> Tuple.pair False)
            ]
            |> Json.dict
            |> Json.map
                (Dict.toList
                    >> List.map
                        (\( k, ( oneLine, v ) ) ->
                            if oneLine then
                                k ++ ": " ++ v

                            else
                                k ++ "\n" ++ v ++ "\n@end"
                        )
                    >> String.join "\n\n"
                    >> (\m ->
                            if large then
                                "<!--\n\n" ++ m ++ "\n\n-->\n\n\n"

                            else
                                "\n<!--\n" ++ m ++ "\n-->"
                       )
                )
        )
        |> Json.maybe
        |> Json.map (Maybe.withDefault "")
