module Block exposing (..)

import Inline
import Json.Decode as Json
import Maybe exposing (withDefault)


indentation : Json.Decoder String
indentation =
    Json.field "indentation" Json.int
        |> Json.andThen
            (\i ->
                if i > 0 && i < 7 then
                    Json.succeed (String.repeat i "#")

                else
                    Json.fail "Indentation must be between 1 and 6"
            )


elements : Json.Decoder String
elements =
    Json.list element
        |> Json.map (String.join "\n\n")


element : Json.Decoder String
element =
    [ Inline.elements
    , Json.field "type" Json.string
        |> Json.andThen typeOf
    ]
        |> Json.oneOf


addAttributes : String -> Json.Decoder String
addAttributes block =
    Json.map
        (\a ->
            if String.isEmpty a then
                block

            else
                a ++ "\n" ++ block
        )
        Inline.toComment


body : Json.Decoder String
body =
    [ element
    , Json.list element |> Json.map (String.join "\n\n")
    , Inline.stringOrList
    ]
        |> Json.oneOf
        |> Json.field "body"


typeOf : String -> Json.Decoder String
typeOf id =
    case id of
        "paragraph" ->
            Json.field "body" Inline.elements
                |> Json.andThen addAttributes

        "line" ->
            addAttributes "---"

        "comment" ->
            Json.map3
                (\start voice text ->
                    "--{{"
                        ++ start
                        ++ (case voice of
                                Nothing ->
                                    ""

                                Just v ->
                                    " " ++ v
                           )
                        ++ "}}--\n"
                        ++ text
                )
                (Inline.start_
                    |> Json.andThen
                        (\start ->
                            case start of
                                Just s ->
                                    Json.succeed s

                                Nothing ->
                                    Json.fail "a comment requires start parameter"
                        )
                )
                Inline.voice_
                (Json.field "body" Inline.elements)
                |> Json.andThen addAttributes

        "gallery" ->
            Json.list Inline.multimedia
                |> Json.field "body"
                |> Json.map (String.join "\n")
                |> Json.andThen addAttributes

        "formula" ->
            Inline.stringOrList
                |> Json.field "body"
                |> Json.map (\f -> "$$ " ++ f ++ " $$")
                |> Json.andThen addAttributes

        "effect" ->
            Json.oneOf
                [ element
                    |> Json.field "body"
                    |> Inline.effect
                    |> Json.map
                        (\( def, content ) ->
                            "{{"
                                ++ def
                                ++ "}}\n"
                                ++ content
                        )
                , element
                    |> Json.list
                    |> Json.field "body"
                    |> Json.andThen
                        (\blocks ->
                            case blocks of
                                [] ->
                                    Json.fail "An effect must have at least one block."

                                [ block ] ->
                                    block
                                        |> Json.succeed
                                        |> Inline.effect
                                        |> Json.map
                                            (\( def, content ) ->
                                                "{{"
                                                    ++ def
                                                    ++ "}}\n"
                                                    ++ content
                                            )

                                _ ->
                                    blocks
                                        |> String.join "\n\n"
                                        |> Json.succeed
                                        |> Inline.effect
                                        |> Json.map
                                            (\( def, content ) ->
                                                "{{"
                                                    ++ def
                                                    ++ "}}\n**********************\n\n"
                                                    ++ content
                                                    ++ "\n\n**********************"
                                            )
                        )
                ]
                |> Json.andThen addAttributes

        "quote" ->
            quote
                |> Json.andThen addAttributes

        "html" ->
            Inline.html (Just "\n\n") body

        "ascii" ->
            asciiArt |> Json.andThen addAttributes

        "chart" ->
            chart |> Json.andThen addAttributes

        "table" ->
            table |> Json.andThen addAttributes

        "list" ->
            Json.field "ordered" Json.bool
                |> Json.maybe
                |> Json.map (Maybe.withDefault False)
                |> Json.andThen
                    (\ordered ->
                        Json.field "body" (Json.list element)
                            |> Json.map
                                (if ordered then
                                    orderedList

                                 else
                                    unorderedList
                                )
                    )
                |> Json.andThen addAttributes

        "code" ->
            Json.map2
                (\c e ->
                    if String.isEmpty e then
                        c

                    else
                        c ++ "\n" ++ e
                )
                code
                execute
                |> Json.andThen addAttributes

        "project" ->
            project |> Json.andThen addAttributes

        "tasks" ->
            tasks |> Json.andThen addAttributes

        "quiz" ->
            quiz |> Json.andThen addAttributes

        _ ->
            Inline.elements


addIndentation : String -> String -> String
addIndentation indent md =
    md
        |> String.lines
        |> List.map (\l -> indent ++ l)
        |> String.join "\n"


quote : Json.Decoder String
quote =
    Json.map2
        (\quote_ by_ ->
            addIndentation "> " <|
                case by_ of
                    Nothing ->
                        quote_

                    Just author ->
                        quote_ ++ "\n\n-- " ++ author
        )
        (Json.field "body" elements)
        (Json.field "by" elements |> Json.maybe)


asciiArt : Json.Decoder String
asciiArt =
    Json.map2
        (\image title_ ->
            "``` ascii"
                ++ title_
                ++ "\n"
                ++ image
                ++ "\n```"
        )
        (Json.field "body" Inline.stringOrList)
        (Inline.elements
            |> Json.field "title"
            |> Json.maybe
            |> Json.map (Maybe.map ((++) "  ") >> Maybe.withDefault "")
        )


chart : Json.Decoder String
chart =
    Inline.stringOrList
        |> Json.field "body"
        |> Json.map (addIndentation "    ")


table : Json.Decoder String
table =
    Json.map3
        (\head alignment rows ->
            let
                orient =
                    alignment
                        |> Maybe.map
                            (List.map
                                (\o ->
                                    case o of
                                        "left" ->
                                            ":----"

                                        "right" ->
                                            "----:"

                                        "center" ->
                                            ":---:"

                                        _ ->
                                            "-----"
                                )
                            )
                        |> Maybe.withDefault
                            (List.repeat
                                (List.length head)
                                "-----"
                            )
            in
            rows
                |> List.map (String.join " | ")
                |> (++) [ String.join " | " orient ]
                |> (++) [ String.join " | " head ]
                |> List.map (\r -> "| " ++ r ++ " |")
                |> String.join "\n"
        )
        (Json.list Inline.elements
            |> Json.field "head"
        )
        (Json.list Json.string
            |> Json.field "alignment"
            |> Json.maybe
        )
        (Json.list Inline.elements
            |> Json.list
            |> Json.field "body"
        )


unorderedList : List String -> String
unorderedList =
    List.map
        (String.lines
            >> List.indexedMap
                (\i l ->
                    if i == 0 then
                        "* " ++ l

                    else
                        "  " ++ l
                )
            >> String.join "\n"
        )
        >> String.join "\n\n"


orderedList : List String -> String
orderedList =
    List.indexedMap
        (\id ->
            String.lines
                >> List.indexedMap
                    (\i l ->
                        if i == 0 then
                            String.fromInt (id + 1) ++ ". " ++ l

                        else
                            "   " ++ l
                    )
                >> String.join "\n"
        )
        >> String.join "\n\n"


code : Json.Decoder String
code =
    Json.map4
        (\c lang title closed ->
            case ( lang, title, closed ) of
                ( Just l, Nothing, _ ) ->
                    "``` "
                        ++ l
                        ++ "\n"
                        ++ c
                        ++ "\n```"

                ( Just l, Just t, Nothing ) ->
                    "``` "
                        ++ l
                        ++ "   "
                        ++ t
                        ++ "\n"
                        ++ c
                        ++ "\n```"

                ( Just l, Just t, Just no ) ->
                    "``` "
                        ++ l
                        ++ "   "
                        ++ (if no then
                                "-"

                            else
                                "+"
                           )
                        ++ t
                        ++ "\n"
                        ++ c
                        ++ "\n```"

                _ ->
                    "```\n" ++ c ++ "\n```"
        )
        (Inline.stringOrList
            |> Json.field "body"
        )
        (Json.string
            |> Json.field "language"
            |> Json.maybe
        )
        (Json.string
            |> Json.field "title"
            |> Json.maybe
        )
        (Json.bool
            |> Json.field "closed"
            |> Json.maybe
        )


project : Json.Decoder String
project =
    Json.map2
        (\files append ->
            String.join "\n" files ++ append
        )
        (Json.list code
            |> Json.field "body"
        )
        execute


execute : Json.Decoder String
execute =
    Inline.stringOrList
        |> Json.field "execute"
        |> Json.map (\s -> "\n" ++ s)
        |> Json.maybe
        |> Json.map (Maybe.withDefault "")


tasks : Json.Decoder String
tasks =
    Json.map3
        (\task done append ->
            (task
                |> List.indexedMap
                    (\i t ->
                        if List.member i done then
                            "- [X] " ++ t

                        else
                            "- [ ] " ++ t
                    )
                |> String.join "\n"
            )
                ++ append
        )
        (Json.field "body" (Json.list Inline.elements))
        (Inline.marked
            |> Json.field "done"
            |> Json.maybe
            |> Json.map (Maybe.withDefault [])
        )
        execute


quiz : Json.Decoder String
quiz =
    Json.map4
        (\q hints answer append ->
            case hints of
                Nothing ->
                    q ++ answer ++ append

                Just h ->
                    q ++ h ++ answer ++ append
        )
        quizType
        quizHints
        quizAnswer
        execute


quizType : Json.Decoder String
quizType =
    Json.field "quizType" Json.string
        |> Json.andThen
            (\type_ ->
                case type_ of
                    "input" ->
                        Inline.inputText
                            |> Json.map (\i -> "[[" ++ i ++ "]]\n")

                    "selection" ->
                        Inline.inputSelection
                            |> Json.map (\i -> "[[" ++ i ++ "]]\n")

                    "single-choice" ->
                        Json.map2
                            (\options solution ->
                                (options
                                    |> List.indexedMap
                                        (\i option ->
                                            if List.member i solution then
                                                "[(X)] " ++ option

                                            else
                                                "[( )] " ++ option
                                        )
                                    |> String.join "\n"
                                )
                                    ++ "\n"
                            )
                            Inline.inputOptions
                            (Json.field "solution" Inline.marked)

                    "multiple-choice" ->
                        Json.map2
                            (\options solution ->
                                (options
                                    |> List.indexedMap
                                        (\i option ->
                                            if List.member i solution then
                                                "[[X]] " ++ option

                                            else
                                                "[[ ]] " ++ option
                                        )
                                    |> String.join "\n"
                                )
                                    ++ "\n"
                            )
                            Inline.inputOptions
                            (Json.field "solution" Inline.marked)

                    "matrix" ->
                        Json.map2
                            (\head row ->
                                let
                                    header =
                                        head
                                            |> List.map
                                                (\column ->
                                                    if String.contains ")" column then
                                                        "[ " ++ column ++ " ]"

                                                    else
                                                        "( " ++ column ++ " )"
                                                )
                                            |> String.join " "

                                    body_ =
                                        row
                                            |> List.map
                                                (\( isSingleChoice, solution, opt ) ->
                                                    head
                                                        |> List.indexedMap
                                                            (\i _ ->
                                                                if List.member i solution then
                                                                    if isSingleChoice then
                                                                        "(X)"

                                                                    else
                                                                        "[X]"

                                                                else if isSingleChoice then
                                                                    "( )"

                                                                else
                                                                    "[ ]"
                                                            )
                                                        |> String.join " "
                                                        |> (\r -> "[  " ++ r ++ "  ] " ++ opt)
                                                )
                                            |> String.join "\n"
                                in
                                "[ " ++ header ++ " ]\n" ++ body_ ++ "\n"
                            )
                            (Json.field "head" (Json.list (Json.oneOf [ Inline.elements, Inline.elements ])))
                            (Json.field "body"
                                (Json.list
                                    (Json.oneOf
                                        [ Json.field "single-choice"
                                            (Json.map2 (\solution opt -> ( True, solution, opt ))
                                                (Json.field "solution" Inline.marked)
                                                (Json.field "body" Inline.elements)
                                            )
                                        , Json.field "multiple-choice"
                                            (Json.map2 (\solution opt -> ( False, solution, opt ))
                                                (Json.field "solution" Inline.marked)
                                                (Json.field "body" Inline.elements)
                                            )
                                        ]
                                    )
                                )
                            )

                    "gap-text" ->
                        Json.field "body" element

                    "generic" ->
                        Json.succeed "[[!]]\n"

                    _ ->
                        Json.fail "Supported quiz types are \"input\", \"selection\", \"single-choice\", \"multiple-choice\", \"matrix\", \"gap-text\", and \"generic\"."
            )


quizHints : Json.Decoder (Maybe String)
quizHints =
    Json.list Inline.elements
        |> Json.map (List.map ((++) "[[?]] ") >> String.join "\n")
        |> Json.field "hints"
        |> Json.maybe


quizAnswer : Json.Decoder String
quizAnswer =
    Json.field "answer" elements
        |> Json.map (\s -> "\n************************\n\n" ++ s ++ "\n\n************************")
        |> Json.maybe
        |> Json.map (Maybe.withDefault "")
