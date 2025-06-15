module Block exposing (..)

import Html exposing (blockquote)
import Inline
import Json.Decode as Json


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


elementOrString : Json.Decoder String
elementOrString =
    Json.oneOf
        [ Json.string
        , element
        ]


elementsOrString : Json.Decoder String
elementsOrString =
    Json.oneOf
        [ Json.string
        , elements
        ]


elements =
    [ element
    , Json.list element
        |> Json.map (String.join "\n\n")
    ]
        |> Json.oneOf


element : Json.Decoder String
element =
    Json.field "type" Json.string
        |> Json.andThen typeOf


addAttributes : String -> Json.Decoder String
addAttributes block =
    Json.map (\a -> a ++ "\n" ++ block) Inline.toComment


body : Json.Decoder String
body =
    [ element
    , Json.list element |> Json.map (String.join "\n\n")
    , Inline.stringOrList
    ]
        |> Json.oneOf
        |> Json.field "body"


inlines : Json.Decoder String
inlines =
    [ Inline.stringOrList
    , Inline.element
    , Json.list Inline.elementsOrString |> Json.map (String.join " ")
    ]
        |> Json.oneOf


typeOf : String -> Json.Decoder String
typeOf id =
    case id of
        "paragraph" ->
            Json.field "body" inlines
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
                (Json.field "body" inlines)
                |> Json.andThen addAttributes

        "gallery" ->
            Json.list (Inline.link True)
                |> Json.field "body"
                |> Json.map (String.join "\n")
                |> Json.field "gallery"
                |> Json.andThen addAttributes

        "formula" ->
            Inline.stringOrList
                |> Json.field "body"
                |> Json.map (\f -> "$$ " ++ f ++ " $$")
                |> Json.andThen addAttributes

        "effect" ->
            Json.oneOf
                [ elementOrString
                    |> Json.field "body"
                    |> Inline.effect
                    |> Json.map
                        (\( def, content ) ->
                            "{{"
                                ++ def
                                ++ "}}\n"
                                ++ content
                        )
                , elementOrString
                    |> Json.list
                    |> Json.field "body"
                    |> Json.map (String.join "\n\n")
                    |> Inline.effect
                    |> Json.map
                        (\( def, content ) ->
                            "{{"
                                ++ def
                                ++ "}}\n**********************\n\n"
                                ++ content
                                ++ "\n\n**********************"
                        )
                ]
                |> Json.andThen addAttributes

        "blockquote" ->
            blockquote
                |> Json.andThen addAttributes

        _ ->
            Json.fail <| "unknown block type: " ++ id


blockquote : Json.Decoder String
blockquote =
    [ Json.field "body" elementOrString
    , Json.field "body" elementsOrString
    ]
        |> Json.oneOf
        |> Json.map (addIndentation "> ")



{- Json.oneOf
   [ Json.map2
       (\attr elem ->
           (if String.isEmpty attr then
               ""

            else
               attr ++ "\n"
           )
               ++ elem
       )
       Inline.toComment
       (Json.oneOf
           [ paragraph
           , horizontalRule
           , blockquote
           , comment
           , unorderedList
           , orderedList
           , assciiArt
           , chart
           , citation
           , quiz
           , gallery
           , formula
           , table
           , code
           , project

           --, survey
           , effect
           , tasks
           , Json.string
           ]
       )
   , Inline.html (Just "\n\n") elementsOrString
   ]
-}
{- , blockquote
   formula : Json.Decoder String
   formula =
       Inline.stringOrList
           |> Json.field "formula"
           |> Json.map (\f -> "$$ " ++ f ++ " $$")


   blockquote : Json.Decoder String
   blockquote =
       [ Json.field "blockquote" elementsOrString
       , Json.field "q" elementsOrString
       ]
           |> Json.oneOf
           |> Json.map (addIndentation "> ")


   effect : Json.Decoder String
   effect =
       Json.oneOf
           [ elementOrString
               |> Json.field "effect"
               |> Inline.effect
               |> Json.map
                   (\( def, body ) ->
                       "{{"
                           ++ def
                           ++ "}}\n"
                           ++ body
                   )
           , elementsOrString
               |> Json.field "effect"
               |> Inline.effect
               |> Json.map
                   (\( def, body ) ->
                       "{{"
                           ++ def
                           ++ "}}\n**********************\n\n"
                           ++ body
                           ++ "\n\n**********************"
                   )
           ]


   table : Json.Decoder String
   table =
       Json.field "table"
           (Json.map3
               (\head orientation rows ->
                   let
                       orient =
                           orientation
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
               (Json.list Inline.elementsOrString
                   |> Json.field "head"
               )
               (Json.list Json.string
                   |> Json.field "orientation"
                   |> Json.maybe
               )
               (Json.list Inline.elementsOrString
                   |> Json.list
                   |> Json.field "rows"
               )
           )


   citation : Json.Decoder String
   citation =
       Json.map2
           (\quote by -> quote ++ "\n\n-- " ++ by)
           (Json.oneOf
               [ Json.field "citation" elementsOrString
               , Json.field "cite" elementsOrString
               ]
           )
           (Json.field "by" Inline.elementsOrString)
           |> Json.map (addIndentation "> ")


   paragraph : Json.Decoder String
   paragraph =
       Json.oneOf
           [ Json.field "paragraph" Inline.elementsOrString
           , Json.field "p" Inline.elementsOrString
           ]


   horizontalRule : Json.Decoder String
   horizontalRule =
       [ Json.field "horizontal rule" (Json.succeed "---")
       , Json.field "hr" (Json.succeed "---")
       ]
           |> Json.oneOf


   list : Json.Decoder (List String)
   list =
       Json.list (Json.oneOf [ elementOrString, elementsOrString ])


   unorderedList : Json.Decoder String
   unorderedList =
       [ Json.field "unordered list" list
       , Json.field "ul" list
       ]
           |> Json.oneOf
           |> Json.map
               (List.map
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
               )


   orderedList : Json.Decoder String
   orderedList =
       [ Json.field "ordered list" list
       , Json.field "ol" list
       ]
           |> Json.oneOf
           |> Json.map
               (List.indexedMap
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
               )


   comment : Json.Decoder String
   comment =
       Json.map3 (\id str voice -> "    --{{" ++ String.fromInt id ++ voice ++ "}}--\n" ++ str)
           (Json.field "id" Json.int)
           (Json.field "comment" Inline.elementsOrString)
           (Json.field "voice" Json.string
               |> Json.maybe
               |> Json.map (Maybe.map ((++) " ") >> Maybe.withDefault "")
           )


   addIndentation : String -> String -> String
   addIndentation indent md =
       md
           |> String.lines
           |> List.map (\l -> indent ++ l)
           |> String.join "\n"


   elements : Json.Decoder String
   elements =
       Json.lazy (\_ -> Json.list element)
           |> Json.map (String.join "\n\n")


   assciiArt : Json.Decoder String
   assciiArt =
       Json.map2
           (\image title_ ->
               "``` ascii"
                   ++ title_
                   ++ "\n"
                   ++ image
                   ++ "\n```"
           )
           ([ Json.field "ascii art" Inline.stringOrList
            , Json.field "ascii" Inline.stringOrList
            ]
               |> Json.oneOf
           )
           (Inline.elementsOrString
               |> Json.field "title"
               |> Json.maybe
               |> Json.map (Maybe.map ((++) "  ") >> Maybe.withDefault "")
           )


   chart : Json.Decoder String
   chart =
       [ Json.field "chart" Inline.stringOrList
       , Json.field "diagram" Inline.stringOrList
       ]
           |> Json.oneOf
           |> Json.map
               (String.lines
                   >> List.map ((++) "    ")
                   >> String.join "\n"
               )


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
           (Json.field "tasks" (Json.list elementsOrString))
           ([ Json.list Json.int
            , Json.list Json.bool
               |> Json.map
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
               |> Json.oneOf
               |> Json.field "done"
               |> Json.maybe
               |> Json.map (Maybe.withDefault [])
           )
           appendix


   quiz : Json.Decoder String
   quiz =
       Json.map4
           (\q hints answer append ->
               case hints of
                   Nothing ->
                       q ++ answer ++ append

                   Just h ->
                       q ++ "\n" ++ h ++ answer ++ append
           )
           quizType
           quizHints
           quizAnswer
           appendix


   quizType : Json.Decoder String
   quizType =
       Json.field "quiz" Json.string
           |> Json.andThen
               (\type_ ->
                   case type_ of
                       "text" ->
                           Inline.inputText
                               |> Json.map (\s -> "[[" ++ s ++ "]]")

                       "selection" ->
                           Inline.inputSelection
                               |> Json.map (\s -> "[[" ++ s ++ "]]")

                       "single-choice" ->
                           Json.map2
                               (\options solution ->
                                   options
                                       |> List.indexedMap
                                           (\i option ->
                                               if List.member i solution then
                                                   "[(X)] " ++ option

                                               else
                                                   "[( )] " ++ option
                                           )
                                       |> String.join "\n"
                               )
                               Inline.inputOptions
                               Inline.inputSolution

                       "multiple-choice" ->
                           Json.map2
                               (\options solution ->
                                   options
                                       |> List.indexedMap
                                           (\i option ->
                                               if List.member i solution then
                                                   "[[X]] " ++ option

                                               else
                                                   "[[ ]] " ++ option
                                           )
                                       |> String.join "\n"
                               )
                               Inline.inputOptions
                               Inline.inputSolution

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

                                       body =
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
                                   "[ " ++ header ++ " ]\n" ++ body
                               )
                               (Json.field "head" (Json.list (Json.oneOf [ Inline.element, Inline.elementsOrString ])))
                               (Json.field "rows"
                                   (Json.list
                                       (Json.oneOf
                                           [ Json.field "single-choice"
                                               (Json.map2 (\solution opt -> ( True, solution, opt ))
                                                   Inline.inputSolution
                                                   (Json.field "option" Inline.elementsOrString)
                                               )
                                           , Json.field "multiple-choice"
                                               (Json.map2 (\solution opt -> ( False, solution, opt ))
                                                   Inline.inputSolution
                                                   (Json.field "option" Inline.elementsOrString)
                                               )
                                           ]
                                       )
                                   )
                               )

                       "gap-text" ->
                           Json.field "body" elementOrString

                       "generic" ->
                           Json.succeed "[[!]]\n"

                       _ ->
                           Json.fail "Supported quiz types are \"text\", \"selection\", \"single-choice\", \"multiple-choice\", \"matrix\", \"gap-text\", and \"generic\"."
               )


   quizHints : Json.Decoder (Maybe String)
   quizHints =
       Json.list Inline.elementsOrString
           |> Json.map (List.map ((++) "[[?]] ") >> String.join "\n")
           |> Json.field "hints"
           |> Json.maybe


   quizAnswer : Json.Decoder String
   quizAnswer =
       Json.field "answer" elementsOrString
           |> Json.map (\s -> "\n************************\n\n" ++ s ++ "\n\n************************")
           |> Json.maybe
           |> Json.map (Maybe.withDefault "")


   gallery : Json.Decoder String
   gallery =
       Json.list Inline.link
           |> Json.map (String.join "\n")
           |> Json.field "gallery"


   project : Json.Decoder String
   project =
       Json.map2
           (\files append ->
               String.join "\n" files ++ append
           )
           ([ Json.list code
            , Json.map List.singleton code
            ]
               |> Json.oneOf
               |> Json.field "project"
           )
           appendix


   code : Json.Decoder String
   code =
       Json.map5
           (\c lang title closed attr ->
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
               |> Json.field "code"
           )
           (Json.string
               |> Json.field "language"
               |> Json.maybe
           )
           (Json.string
               |> Json.field "name"
               |> Json.maybe
           )
           (Json.bool
               |> Json.field "closed"
               |> Json.maybe
           )
           Inline.attributes


   appendix : Json.Decoder String
   appendix =
       Inline.stringOrList
           |> Json.field "appendix"
           |> Json.map (\s -> "\n" ++ s)
           |> Json.maybe
           |> Json.map (Maybe.withDefault "")
-}
