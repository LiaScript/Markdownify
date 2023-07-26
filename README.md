# LiaScript-Markdownify

Create LiaScript documents from a common JSON-model

## Install

Install directly via npm:

``` bash
npm install @liascript/markdownify
```

## Usage

Currently there is only one function that takes as an input-parameter either a string or a JSON/Object directly.
`liascriptify` will return a promise that will either return the correct LiaScript-Markdown document or it will return an error message.


``` typescript
import liascriptify from './node_modules/@liascript/markdownify/dist/lib'

const example = {
  meta: {
    author: 'Superhero',
    email: 'superhero@web.de',
  },
  sections: [
    {
      title: 'Title',
      indent: 1,
      body: [
        'This can be either a list of Strings',
        'that are interpreted as Markdown-blocks',
        {
          paragraph: [
            { string: 'Or a set of ' },
            {
              bold: [
                { string: 'more sophisticated '},
                { superscript: 'elements' },
              ],
            },
            '!',
          ],
        },
      ],
    },
  ],
}

liascriptify(example)
  .then((doc: string) => {
    console.log('ok', doc)
  })
  .catch((err: string) => {
    console.warn('err', err)
  })
```

## Base structure

The basic structure of a LiaScript-Json format is rather simple, you can either directly pass Markdown as a string or you can break it down to collections of block and inline elements. Every Json-file has the following structure:

``` json
{
  "meta": {
    "author": "Superhero",
    "email": "superhero@web.de"
  },
  "sections": [
    {
      "title": "Main Title",
      "indent": 1,
      "body": [
        "This can be either a list of Strings",
        "that are interpreted as Markdown-blocks",
        {
          "paragraph": [
            {
              "string": "Or a set of "
            },
            {
              "bold": [
                {
                  "string": "more sophisticated "
                },
                {
                  "superscript": "elements"
                }
              ]
            },
            "!"
          ]
        }
      ]
    }
  ]
}
```

The `meta` fields are optional, but you can define a global filed on top that will define the main-header. The `sections` are required and are a list of single "pages", which consists of a `title`, `indent`, and a `body` for the content. Additionally it is possible to add another `meta` field to every section.

``` markdown
<!--

author: Superhero

email: superhero@web.de

-->


# Main Title

This can be either a list of Strings

that are interpreted as Markdown-blocks

Or a set of __more sophisticated ^elements^__!
```

## Body: Block-Elements

``` markdown
# Body 1

It is possible to pass directly valid __LiaScript/Markdown__ code to the body.

This can contain multiple blocks that are separated by newlines.


## Body 2

Or to keep it clean

You can pass multiple strings, that are treated as blocks

... each
```

---

``` json
{
  "sections": [
    {
      "title": "Body 1",
      "indent": 1,
      "body": "It is possible to pass directly valid __LiaScript/Markdown__ code to the body.\n\nThis can contain multiple blocks that are separated by newlines."
    },
    {
      "title": "Body 2",
      "indent": 2,
      "body": [
        "Or to keep it clean",
        "You can pass multiple strings, that are treated as blocks",
        "... each"
      ]
    }
  ]
}
```



## Blocks

### Paragraphs

``` markdown
### `paragraph` or `p`

A paragraph is either a string,

but it can also__be a simple list__^of multiple $ inline elements $^.
```

---

``` json
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
}
```

### Unordered Lists

``` markdown
### `unordered list` or `ul`

* is either a list of strings,

* <!-- style=color: red; -->
  or a list of further Blocks an tables.

* But it is also possible
  
  * put group multiple blocks into
  
  * a single list
```

---

``` json
{
  "title": "`unordered list` or `ul`",
  "indent": 3,
  "body": [
    {
      "unordered list": [
        "is either a list of strings,",
        {
          "paragraph": "or a list of further Blocks an tables.",
          "attributes": {
            "style": "color: red;"
          }
        },
        [
          "But it is also possible",
          {
            "ul": ["put group multiple elements within", "a single list"]
          }
        ]
      ]
    }
  ]
}
```


### Ordered Lists

``` markdown
### `ordered list` or `ol`

1. behave similar to unordered lists,

2. the only __difference__ is

3. <!-- style=color: red; -->
   that the blocks are identified by their appearance.

4. Grouping works exactly the same way,
   
   1. simply put multiple elements
   
   2. into a single list
```

-------------

``` json
{
  "title": "`ordered list` or `ol`",
  "indent": 3,
  "body": [
    {
      "ordered list": [
        "behave similar to unordered lists,",
        {
          "paragraph": "the only __difference__ is"
        },
        {
          "paragraph": "that the blocks are identified by their appearance.",
          "attributes": {
            "style": "color: red;"
          }
        },
        [
          "Grouping works exactly the same way,",
          {
            "ul": ["simply put multiple elements", "into a single list"]
          }
        ]
      ]
    }
  ]
}
```

### Horizontal Rule

``` markdown
### `horizontal rule` or `hr`

A horizontal rule is a simple line that separates two blocks:

---

or

---
```

---

``` json
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
}
```

### Blockquotes

``` markdown
### `blockquote` or `q`

> This can also be a simple string...

---

> __A list of multiple strings__
> 
> These are interpreted as separate blocks

---

> Or a combination
> 
> > of various different blocks
> > 
> > * lists
> > 
> > * blockquotes
> > 
> > * tables
> > 
> > * etc.
```

---

``` json
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
}
```

### Citation

``` markdown
### `citation` or `cite`

Citations are a special LiaScript case of a blockquote, which will be rendered differently, but behave like normal blockquotes.

> If you want your children to be intelligent, read them fairy tales.If you want them to be more intelligent, read them more fairy tales.
> 
> -- Albert Einstein
```

---

``` json
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
}
```

### Comments & TTS

``` markdown
### `comment`

    --{{1 Ukrainian Female}}--
Comments in LiaScript are these parts that are spoken out loud.They will be displayed only in `Textbook` mode.Every comment requires an `id`, to mark the animation step, when it should be spoken out loud.Additionally you can set the voice, which is optional in contrast to the id.
```

---

``` json
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
}
```

### ASCII-Art

```` markdown
### `ascii art` or `ascii`

``` ascii    Title is optional and will be displayed as an image __caption__
+------+   +-----+   +-----+   +-----+
|      |   |     |   |     |   |     |
| Foo  +-->| Bar +---+ Baz |<--+ Moo |
|      |   |     |   |     |   |     |
+------+   +-----+   +--+--+   +-----+
              ^         |
              |         V
.-------------+-----------------------.
| Hello here and there and everywhere |
'-------------------------------------'
```
````

---

``` json
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
}
```

### Charts

``` markdown
### `chart` or `diagram`

                                diagram title       
    1.5 |           *                     (* stars) 
        |                                           
      y |        *      *                           
      - |      *          *                         
      a |     *             *       *               
      x |    *                 *                    
      i |   *                                       
      s |  *                                        
        | *                              *        * 
      0 +------------------------------------------ 
       2.0              x-axis                100 
```

---

``` json
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
}
```


### Quizzes


#### Text-Input

``` markdown
#### `text`

What did the fish say, when he hit the wall?

[[dam]]
```

#### Selection

``` markdown
#### `selection`

The solution is defined by its position in the option list

[[option 0 | ( option 1 ) | __this is Bold and wrong__]]
```

#### Single-Choice

``` markdown
#### `single-choice`

What did the fish say, when he hit the wall?

- [( )] option 0
- [(X)] option 1
- [( )] __option 3__
```

#### Multiple-Choice

``` markdown
#### `multiple-choice`

What did the fish say, when he hit the wall?

- [[ ]] option 0
- [[X]] option 1
- [[X]] __option 3__
```

#### Gap-Text

``` markdown
#### `gap-text`

What did the fish say, when he hit the wall?

__Some Inlines__ [[damn]] some more test [[ option1 | ( option2 ) | option3 ]] some more test 
```

---

``` json
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
}
```

#### Tweaks

``` markdown
#### `selection` part 2

The solution is defined by its position in the option list...

... But, as there are multiple options, you can define also multiple solutions too.

<!-- data-trials=5 -->
[[( option 0 ) | option 1 | ( __this is Bold__ )]]
[[?]] hint number one
[[?]] the second and last hint
************************

These blocks will only be visible...

... if and only if, the quiz is solved

or if the user clicks onto the resolve button.

************************
```

---

``` json
{
  "title": "`selection` part 2",
  "indent": 4,
  "body": [
    "The solution is defined by its position in the option list...",
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
        "These blocks will only be visible...",
        "... if and only if, the quiz is solved",
        "or if the user clicks onto the resolve button."
      ],
      "attributes": {
        "data-trials": "5"
      }
    }
  ]
}
```

### Surveys

TODO

### Gallery

``` markdown
### `gallery`

A gallery is simply a collection of multimedia links

![LiaScript Live-Editor](https://liascript.github.io/img/LiveEditor.jpg "More and optional information.")
?[Magnetic's ELM Podcast: One More Summer Sun](https://soundcloud.com/magnetic-magazine/magnetics-elm-podcast-one-more)
!?[Some random video](https://www.youtube.com/watch?v=q_Usix3nyGA)
??[](https://falstad.com/circuit/circuitjs.html)
```

---

``` json
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
}
```

### Tasks

``` markdown
### `tasks`

Tasks are defined by a task and by a done list:

- [X] task 1
- [ ] task 2
- [X] task 3

Additionally it is possible to define a done list with only checked positions:

- [X] task 1
- [ ] task 2
- [X] task 3
```

---

``` json
{
  "title": "`tasks`",
  "indent": 3,
  "body": [
    "Tasks are defined by a task and by a done list:",
    {
      "tasks": ["task 1", "task 2", "task 3"],
      "done": [true, false, true]
    },
    "Additionally it is possible to define a done list with only checked positions:",
    {
      "tasks": ["task 1", "task 2", "task 3"],
      "done": [0, 2]
    }
  ]
}
```

### Tables

``` markdown
### `table`

Tables are defined by a head and a row, the orientation is optional

| head 1 | head 2 | __head 3__ |
| :----- | -----: | :--------: |
| 1      |      2 |      3     |
| 4      |      5 |      6     |
| 7      |      8 |      9     |
```

---

``` json
{
  "title": "`table`",
  "indent": 3,
  "body": [
    "Tables are defined by a head and a row, the orientation is optional",
    {
      "table": {
        "head": ["head 1", "head 2", [{ "bold": "head 3" }]],
        "orientation": ["left", "right", "center"],
        "rows": [
          ["1", "2", "3"],
          ["4", "5", "6"],
          ["7", "8", "9"]
        ]
      }
    }
  ]
}
```

### Code-Snippets

The code is passed as a single string or a list of strings, language, name, and closed are optional parameters.

```` markdown
### `code`

``` javascript   -test.js
This is a simple code block
with multiple lines
and a specific language
for syntax highlighting
```
````

---

``` json
{
  "title": "`code`",
  "indent": 3,
  "body": [
    {
      "code": [
        "This is a simple code block",
        "with multiple lines",
        "and a specific language",
        "for syntax highlighting"
      ],
      "language": "javascript",
      "name": "test.js",
      "closed": true
    }
  ]
}
```

### Projects

A project can be defined by a single code-block or by a list of code-blocks.
Additionally it is possible to add an appendix, which is either a script or a macro that evaluates to a script, and that defines how the code can be made executable.


```` markdown
### `project`

``` javascript   var.js
var i = 0;
```
``` javascript   alert.js
alert("Hallo Welt")
```
@eval
````

---

``` json
{
  "title": "`project`",
  "indent": 3,
  "body": [
    {
      "project": [
        {
          "code": "var i = 0;",
          "language": "javascript",
          "name": "var.js"
        },
        {
          "code": "alert(\"Hallo Welt\")",
          "language": "javascript",
          "name": "alert.js"
        }
      ],
      "appendix": "@eval"
    }
  ]
}
```

### HTML

``` markdown
### `html`

<section "style"="color: red;">This is a simple HTML element</section>
```

---

``` json
{
  "title": "`html`",
  "indent": 3,
  "body": [
    {
      "html": "section",
      "body": [{ "paragraph": "This is a simple HTML element" }],
      "attributes": {
        "style": "color: red;"
      }
    }
  ]
}
```

## Inline Elements