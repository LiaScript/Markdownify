module Example exposing (..)


json =
    """{
  "meta": {
    "author": "LiaScript",
    "version": "1.2",
    "lang": "de"
  },
  "sections": [
    {
      "meta": {
        "author": "LiaScript",
        "email": "author@web.de"
      },
      "indent": 1,
      "title": "Base",
      "body": "In the simplest case, a section consists of two strings for one for the title and one for the body. The indentation is a required value between 0 and 6 and defines the number of starting hash-tags. For the __title__ and the __body__ elements it is already possible to use *LiaScript-syntax* directly."
    },
    {
      "indent": 2,
      "title": "Blocks",
      "body": [
        "__If you want to have multiple paragraphs:__",
        "- Simply add multiple strings into a list",
        "- All strings will be separated by a single newline ..."
      ]
    },
    {
      "indent": 3,
      "title": "`paragraph` or `p`",
      "body": [
        {
          "paragraph": "A paragraph is either a string,"
        },
        {
          "paragraph": [
            "but it can also",
            {
              "bold": [
                {
                  "string": "be a simple list"
                }
              ]
            },
            {
              "superscript": [
                "of multiple ",
                {
                  "formula": "inline elements"
                }
              ]
            },
            "."
          ]
        }
      ]
    },
    {
      "title": "`unordered list` or `ul`",
      "indent": 3,
      "body": [
        {
          "unordered list": [
            "is either a list of strings",
            {
              "paragraph": ", or a list of further Blocks an tables.",
              "attributes": {
                "style": "color: red;"
              }
            },
            [
              "But it is also possible",
              {
                "ul": [
                  "put group multiple elements within",
                  "a single list"
                ]
              }
            ]
          ]
        }
      ]
    },
    {
      "title": "`ordered list` or `ol`",
      "indent": 3,
      "body": [
        {
          "ordered list": [
            "behave similar to unordered lists",
            {
              "paragraph": ", the only difference is, that the blocks are identified by their appearance.",
              "attributes": {
                "style": "color: red;"
              }
            },
            [
              "Grouping works exactly the same way,",
              {
                "ul": [
                  "simply put multiple elements",
                  "into a single list"
                ]
              }
            ]
          ]
        }
      ]
    },
    {
      "title": "`horizontal rule` or `hr`",
      "indent": 3,
      "body": [
        "A horizontal rule is a simple line that separates two blocks:",
        {
          "hr": null
        },
        "or",
        {
          "horizontal rule": null
        }
      ]
    },
    {
      "title": "`blockquote` or `q`",
      "indent": 3,
      "body": [
        {
          "blockquote": "This can also be a simple string..."
        },
        {
          "hr": null
        },
        {
          "blockquote": [
            "__A list of multiple strings__",
            "These are interpreted as separate blocks"
          ]
        },
        {
          "hr": null
        },
        {
          "blockquote": [
            {
              "paragraph": "Or a combination"
            },
            {
              "q": [
                "of various different blocks",
                {
                  "ul": [
                    "lists",
                    "blockquotes",
                    "tables",
                    "etc."
                  ]
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "title": "`citation` or `cite`",
      "indent": 3,
      "body": [
        {
          "paragraph": "Citations are a special LiaScript case of a blockquote, which will be rendered differently, but behave like normal blockquotes."
        },
        {
          "citation": [
            {
              "p": [
                "If you want your children to be intelligent, read them fairy tales.",
                "If you want them to be more intelligent, read them more fairy tales."
              ]
            }
          ],
          "by": "Albert Einstein"
        }
      ]
    },
    {
      "title": "`comment`",
      "indent": 3,
      "body": [
        {
          "comment": [
            "Comments in LiaScript are these parts that are spoken out loud.",
            "They will be displayed only in `Textbook` mode.",
            "Every comment requires an `id`, to mark the animation step, when it should be spoken out loud.",
            "Additionally you can set the voice, which is optional in contrast to the id"
          ],
          "id": 1,
          "voice": "Ukrainian Female"
        }
      ]
    },
    {
      "title": "`ascii art` or `ascii`",
      "indent": 3,
      "body": [
        {
          "ascii": [
            "+------+   +-----+   +-----+   +-----+",
            "|      |   |     |   |     |   |     |",
            "| Foo  +-->| Bar +---+ Baz |<--+ Moo |",
            "|      |   |     |   |     |   |     |",
            "+------+   +-----+   +--+--+   +-----+",
            "              ^         |",
            "              |         V",
            ".-------------+-----------------------.",
            "| Hello here and there and everywhere |",
            "'-------------------------------------'"
          ],
          "title": "  Title is optional and will be displayed as an image __caption__"
        }
      ]
    },
    {
      "title": "`chart` or `diagram`",
      "indent": 3,
      "body": [
        {
          "chart": [
            "                            diagram title       ",
            "1.5 |           *                     (* stars) ",
            "    |                                           ",
            "  y |        *      *                           ",
            "  - |      *          *                         ",
            "  a |     *             *       *               ",
            "  x |    *                 *                    ",
            "  i |   *                                       ",
            "  s |  *                                        ",
            "    | *                              *        * ",
            "  0 +------------------------------------------ ",
            "   2.0              x-axis                100   "
          ]
        }
      ]
    },
    {
      "title": "`quiz`",
      "indent": 3,
      "body": "asfda"
    },
    {
      "title": "`text`",
      "indent": 4,
      "body": [
        "What did the fish say, when he hit the wall?",
        {
          "quiz": "text",
          "solution": "dam"
        }
      ]
    },
    {
      "title": "`selection`",
      "indent": 4,
      "body": [
        "The solution is defined by its position in the option list",
        {
          "quiz": "selection",
          "solution": 1,
          "options": [
            "option 0",
            "option 1",
            [
              {
                "bold": "this is Bold and wrong"
              }
            ]
          ]
        },
        {
          "hr": null
        },
        "... But, as there are multiple options, you can define also multiple solutions too.",
        {
          "quiz": "selection",
          "solution": [
            0,
            2
          ],
          "options": [
            "option 0",
            "option 1",
            [
              {
                "bold": "this is Bold"
              }
            ]
          ],
          "hints": [
            "hint number one",
            "the second and last hint"
          ],
          "answer": [
            "asdfasfd",
            "asdfasfddf"
          ],
          "attributes": "'data-trials'='11'"
        }
      ]
    },
    {
      "title": "`single-choice`",
      "indent": 4,
      "body": [
        "What did the fish say, when he hit the wall?",
        {
          "quiz": "single-choice",
          "solution": 1,
          "options": [
            "option 0",
            "option 1",
            [
              {
                "bold": "option 3"
              }
            ]
          ]
        }
      ]
    },
    {
      "title": "`multiple-choice`",
      "indent": 4,
      "body": [
        "What did the fish say, when he hit the wall?",
        {
          "quiz": "multiple-choice",
          "solution": 1,
          "options": [
            "option 0",
            "option 1",
            [
              {
                "bold": "option 3"
              }
            ]
          ]
        }
      ]
    },
    {
      "title": "`gap-text`",
      "indent": 4,
      "body": [
        "What did the fish say, when he hit the wall?",
        {
          "quiz": "gap-text",
          "body": {
            "p": [
              {
                "bold": "Some Inlines"
              },
              " ",
              {
                "input": "text",
                "solution": "damn"
              },
              " some more test ",
              {
                "input": "selection",
                "solution": 1,
                "options": [
                  "option1",
                  "option2",
                  "option3"
                ]
              },
              " some more test "
            ]
          }
        }
      ]
    },
    {
      "title": "`gallery`",
      "indent": 3,
      "body": [
        "A gallery is simply a collection of multimedia links",
        {
          "gallery": [
            {
              "link": "image",
              "url": "https://liascript.github.io/img/LiveEditor.jpg",
              "alt": "LiaScript Live-Editor",
              "title": "More and optional information."
            },
            {
              "link": "audio",
              "url": "https://soundcloud.com/magnetic-magazine/magnetics-elm-podcast-one-more",
              "alt": "Magnetic's ELM Podcast: One More Summer Sun"
            },
            {
              "link": "video",
              "url": "https://www.youtube.com/watch?v=q_Usix3nyGA",
              "alt": "Some random video"
            },
            {
              "link": "embed",
              "url": "https://falstad.com/circuit/circuitjs.html"
            }
          ]
        }
      ]
    },
    {
      "title": "`formula`",
      "indent": 3,
      "body": [
        {
          "formula": "x = \\frac{1}{3}"
        }
      ]
    }
  ]
}"""
