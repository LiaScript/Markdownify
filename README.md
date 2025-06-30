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
  "meta": {
    "author": "Superhero",
    "email": "superhero@web.de"
  },
  "sections": [
    {
      "title": "Title",
      "indent": 1,
      "body": [
        "This can be either a list of Strings, that are interpreted as Markdown-blocks",
        {
          "type": "Paragraph",
          "body": [
            "This can be predefined types of blocks, like a paragraph, which can be either a string or a set of ",
            {
              "type": "bold",
              "body": [
                "more sophisticated ",
                {
                  "type": "sup",
                  "body": "inline elements"
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
      "title": "Title",
      "indent": 1,
      "body": [
        "This can be either a list of Strings, that are interpreted as Markdown-blocks",
        {
          "type": "Paragraph",
          "body": [
            "This can be predefined types of blocks, like a paragraph, which can be either a string or a set of ",
            {
              "type": "bold",
              "body": [
                "more sophisticated ",
                {
                  "type": "sup",
                  "body": "inline elements"
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

# Title

This can be either a list of Strings, that are interpreted as Markdown-blocks

This can be predefined types of blocks, like a paragraph, which can be either a string or a set of __more sophisticated ^inline elements^__!
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

Each block has a `type` and a `body` and an optional `attr` parameter.

The `type` is a string, which defines the type of the block:

- `Paragraph`: Paragraphs are simple text blocks, which can contain inline elements.
- `Line`: Lines are horizontal rules that separate content.
- `List`: Ordered or unordered lists of items.
- `Quote`: Quotes are block-level citations of text.
- `Comment`: Comments are notes or annotations within the content.
- `Ascii art`: ASCII art blocks are representations of images using characters.
- `Chart`: Charts are visual representations of data.
- `Quiz`: Quizzes are interactive questions for assessment.
- `Gallery`: Galleries are collections of images or media.
- `Tasks`: Tasks are actionable items or to-do lists.
- `Table`: Tables are structured data representations.
- `Code`: Code blocks are used to display programming code or scripts.
- `Project`: Project blocks are used to represent larger initiatives or collections of tasks.
- `Html`: HTML blocks are used to include raw HTML code.

The body is either a string or a list of strings, depending on the block-type a list of blocks or strings (e.g. lists, quotes), which are interpreted as blocks.

The `attr` parameter is an object that can contain additional attributes for the block, such as `style`, `id`, or other custom attributes.

### Paragraphs

Paragraphs are the most basic block type in LiaScript. They can be simple strings or more complex structures that include inline elements.

``` markdown
### `Paragraph`

A paragraph is either a string,

but it can also__a string as well or a list ^of multiple _inline elements_^__.
```

---

``` json
{
  "indent": 3,
  "title": "`Paragraph`",
  "body": [
    {
      "type": "Paragraph",
      "body": "A paragraph is either a string,"
    },
    {
      "type": "Paragraph",
      "body": [
        "but it can also",
        {
          "type": "bold",
          "body": [
            "a string as well or a list ",
            {
              "type": "sup",
              "body": [
                "of multiple ",
                {
                  "type": "italic",
                  "body": "inline elements"
                }
              ]
            }
          ]
        },
        "."
      ]
    }
  ]
}
```

### Lists

``` markdown
### Lists

Lists are either ordered or unordered list. We call itemize the unordered list and enumerate the ordered or numbered list.

* All elements of a list consist either as string ...

* <!-- "style"="color: red;" -->
  ... or of different LiaScript blocks.

* __If you need to pass multiple blocks into one list element.__
  
  1. Simply add a JSON-list,
  
  2. With multiple different Blocks.
  
  3. As you can see you can also apply nesting
     
     in enumerate blocks as well ....
```

---

``` json
{
  "title": "Lists",
  "indent": 3,
  "body": [
    "Lists are either ordered or unordered list. We call itemize the unordered list and enumerate the ordered or numbered list.",
    {
      "type": "List",
      "body": [
        "All elements of a list consist either as string ...",
        {
          "type": "Paragraph",
          "body": "... or of different LiaScript blocks.",
          "attr": {
            "style": "color: red;"
          }
        },
        [
          "__If you need to pass multiple blocks into one list element.__",
          {
            "type": "List",
            "ordered": true,
            "body": [
              "Simply add a JSON-list,",
              {
                "type": "Paragraph",
                "body": "With multiple different Blocks."
              },
              [
                "As you can see you can also apply nesting",
                "in enumerate blocks as well ...."
              ]
            ]
          }
        ]
      ]
    }
  ]
}
```



### Lines - Horizontal Rules

``` markdown
### `line`

A line or a horizontal rule is a simple block element to separate blocks:

---

and of course, lines can also be styled:

<!-- "style"="border:none; border-top: 3px dashed" -->
---
```

---

``` json
{
  "title": "`line`",
  "indent": 3,
  "body": [
    "A line or a horizontal rule is a simple block element to separate blocks:",
    {
      "type": "Line"
    },
    "and of course, lines can also be styled:",
    {
      "type": "Line",
      "attr": {
        "style": "border:none; border-top: 3px dashed"
      }
    }
  ]
}
```

### Quote

``` markdown
### `Quote`

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
> > * quotes
> >
> > * tables
> >
> > * etc.

It is also possible to add the origin of the quote with the parameter `by`.
This can be an arbitrary string or even a block.
It will change the appearance of the quote to a citation.

> $$ E = mc^2 $$
>
> -- Albert Einstein
```

---

``` json
{
  "title": "`Quote`",
  "indent": 3,
  "body": [
    {
      "type": "Quote",
      "body": "This can also be a simple string..."
    },
    {
      "type": "Line"
    },
    {
      "type": "Quote",
      "body": [
        "__A list of multiple strings__",
        "These are interpreted as separate blocks"
      ]
    },
    {
      "type": "Line"
    },
    {
      "type": "Quote",
      "body": [
        {
          "type": "Paragraph",
          "body": "Or a combination"
        },
        {
          "type": "Quote",
          "body": [
            "of various different blocks",
            {
              "type": "itemize",
              "body": ["lists", "quotes", "tables", "etc."]
            }
          ]
        }
      ]
    },
    {
      "type": "Paragraph",
      "body": [
        "It is also possible to add the origin of the quote with the parameter `by`.",
        "This can be an arbitrary string or even a block.",
        "It will change the appearance of the quote to a citation."
      ]
    },
    {
      "type": "Quote",
      "body": "$$ E = mc^2 $$",
      "by": "Albert Einstein"
    },
    {
      "type": "Line"
    }
  ]
}
```

### Comments - TTS & Effects - Animations

``` markdown
### `Comment` & `Effect`

--{{0 Ukrainian Female}}--
Comments in LiaScript are these parts that are spoken out loud.
They will be displayed only in `Textbook` mode.
Every comment requires an `start`, to mark the animation step, when it should be spoken out loud.
Additionally, you can set the voice, which is optional otherwise the default voice will be used

{{1}}
I am a Within an effect, the start and stop parameters define, when a block shall appear.

{{2-3}}
**********************

I am a group of different blocks.

* I will appear in animation __step 2__

* and disappear in animation __step 3__

**********************

--{{1}}--
I will speak on animation step 1 with the default voice.
And, I will be shown in `Textbook` mode below the upper effect group.

{{!>}}
Setting `playback` to true, will add a button that can later be used to read this text in with the default voice.

{{3-5 !> UK English Male}}
**********************

This effect shows all options, it will appear at step 3 and disappear at 5

While adding a playback-button and changing the voice.

--{{3}}--
Keep in mind, that effects contain further effects and comments.

{{4}}
> Added quote to animations...

**********************
```

---

``` json
{
  "title": "`Comment` & `Effect`",
  "indent": 3,
  "body": [
    {
      "type": "Comment",
      "body": [
        "Comments in LiaScript are these parts that are spoken out loud.",
        "They will be displayed only in `Textbook` mode.",
        "Every comment requires an `start`, to mark the animation step, when it should be spoken out loud.",
        "Additionally, you can set the voice, which is optional otherwise the default voice will be used"
      ],
      "start": 0,
      "voice": "Ukrainian Female"
    },
    {
      "type": "Effect",
      "start": 1,
      "body": [
        "I am a Within an effect, the start and stop parameters define, when a block shall appear."
      ]
    },
    {
      "type": "Effect",
      "start": 2,
      "stop": 3,
      "body": [
        "I am a group of different blocks.",
        {
          "type": "itemize",
          "body": [
            "I will appear in animation __step 2__",
            "and disappear in animation __step 3__"
          ]
        }
      ]
    },
    {
      "type": "Comment",
      "body": [
        "I will speak on animation step 1 with the default voice.",
        "And, I will be shown in `Textbook` mode below the upper effect group."
      ],
      "start": 1
    },
    {
      "type": "Effect",
      "playback": true,
      "body": [
        "Setting `playback` to true, will add a button that can later be used to read this text in with the default voice."
      ]
    },
    {
      "type": "Effect",
      "start": 3,
      "stop": 5,
      "voice": "UK English Male",
      "playback": true,
      "body": [
        "This effect shows all options, it will appear at step 3 and disappear at 5",
        "While adding a playback-button and changing the voice.",
        {
          "type": "Comment",
          "start": 3,
          "body": "Keep in mind, that effects contain further effects and comments."
        },
        {
          "type": "Effect",
          "start": 4,
          "body": {
            "type": "Quote",
            "body": "Added quote to animations..."
          }
        }
      ]
    }
  ]
}
```

### ASCII-Art

```` markdown
### `ascii`

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
  "title": "`ascii`",
  "indent": 3,
  "body": [
    {
      "type": "ascii",
      "title": "  Title is optional and will be displayed as an image __caption__",
      "body": [
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
      ]
    }
  ]
}

```

### Charts

``` markdown
### `Chart`

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
  "title": "`Chart`",
  "indent": 3,
  "body": [
    {
      "type": "Chart",
      "body": [
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
#### `input`

What did the fish say, when he hit the wall?

[[dam]]
```

---

``` json
{
  "title": "`input`",
  "indent": 4,
  "body": [
    "What did the fish say, when he hit the wall?",
    {
      "type": "Quiz",
      "quizType": "input",
      "solution": "dam"
    }
  ]
}
```


#### Selection

``` markdown
#### `selection`

What is the color of the nature?

[[red | ( __green__ ) | blue]]
```

---

``` json
{
  "indent": 4,
  "title": "`selection`",
  "body": [
    "What is the color of the nature?",
    {
      "type": "Quiz",
      "quizType": "selection",
      "body": [
        "red",
        {
          "type": "bold",
          "body": "green"
        },
        "blue"
      ],
      "solution": 1
    }
  ]
}
```

#### Single-Choice

``` markdown
#### Single Choice Quiz

What is 2+2? `console.log(2+2)`

[( )] 3
[(X)] 4
[( )] 5
[( )] $ 2^2 $


If there are more than two options, you can also use a list as solution

[( )] 3
[(X)] 4
[( )] 5
[(X)] $ 2^2 $


... or a list of boolean values

[( )] 3
[(X)] 4
[( )] 5
[(X)] $ 2^2 $
```

---

``` json
{
  "indent": 4,
  "title": "Single Choice Quiz",
  "body": [
    {
      "type": "Paragraph",
      "body": [
        [
          "What is 2+2?",
          {
            "type": "code",
            "body": "console.log(2+2)"
          }
        ]
      ]
    },
    {
      "type": "Quiz",
      "quizType": "single-choice",
      "body": [
        "3",
        "4",
        "5",
        {
          "type": "formula",
          "body": "2^2"
        }
      ],
      "solution": 1
    },
    "If there are more than two options, you can also use a list as solution",
    {
      "type": "Quiz",
      "quizType": "single-choice",
      "body": [
        "3",
        "4",
        "5",
        {
          "type": "formula",
          "body": "2^2"
        }
      ],
      "solution": [1, 3]
    },
    "... or a list of boolean values",
    {
      "type": "Quiz",
      "quizType": "single-choice",
      "body": [
        "3",
        "4",
        "5",
        {
          "type": "formula",
          "body": "2^2"
        }
      ],
      "solution": [false, true, false, true]
    }
  ]
}
```

#### Multiple-Choice

``` markdown
#### `multiple-choice`

Which of these is a scripting language?

[[X]] JavaScript
[[X]] Python
[[ ]] Java
[[ ]] C++
```

---

``` json
{
  "indent": 4,
  "title": "`multiple-choice`",
  "body": [
    "Which of these is a scripting language?",
    {
      "type": "Quiz",
      "quizType": "multiple-choice",
      "body": ["JavaScript", "Python", "Java", "C++"],
      "solution": [0, 1]
    }
  ]
}
```

#### Matrix

Matrix quizzes are basically a combination of single and multiple choice quizzes, which are layed out horizontally, with a solution per row and a body, which is appended to the end.

``` markdown
#### `matrix`

Question...

[ ( Strong ) ( Weak ) ( None ) ]
[    (X)       ( )      ( )    ] Java typing
[    [X]       [X]      [ ]    ] Python features
```
---

``` json
{
  "indent": 4,
  "title": "`matrix`",
  "body": [
    "Question...",
    {
      "type": "Quiz",
      "quizType": "matrix",
      "head": ["Strong", "Weak", "None"],
      "body": [
        {
          "single-choice": {
            "solution": [0],
            "body": "Java typing"
          }
        },
        {
          "multiple-choice": {
            "solution": [0, 1],
            "body": "Python features"
          }
        }
      ]
    }
  ]
}
```

#### Gap-Text

``` markdown
#### `gap-text`

What did the fish say, when he hit the wall?

__Some Inlines__ [[damn]] some more test [[ option1 | ( option2 ) | option3 ]] some more ... [[   text   ]]
```

---

``` json
{
  "title": "`gap-text`",
  "indent": 4,
  "body": [
    "What did the fish say, when he hit the wall?",
    {
      "type": "Quiz",
      "quizType": "gap-text",
      "body": {
        "type": "Paragraph",
        "body": [
          {
            "type": "bold",
            "body": "Some Inlines"
          },
          " ",
          {
            "type": "input",
            "solution": "damn"
          },
          " some more test ",
          {
            "type": "select",
            "solution": 1,
            "body": ["option1", "option2", "option3"]
          },
          " some more ... ",
          {
            "type": "input",
            "solution": "text",
            "length": 10
          }
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

<!-- "data-trials"="5" -->
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
      "type": "Quiz",
      "quizType": "selection",
      "solution": [0, 2],
      "body": [
        "option 0",
        "option 1",
        [
          {
            "type": "bold",
            "body": "this is Bold"
          }
        ]
      ],
      "hints": ["hint number one", "the second and last hint"],
      "answer": [
        "These blocks will only be visible...",
        "... if and only if, the quiz is solved",
        "or if the user clicks onto the resolve button."
      ],
      "attr": {
        "data-trials": 5
      }
    }
  ]
}
```

#### Quiz-Settings

There are more options to tweak the behavior of quizzes, which can be set by adding `attr` to the quiz-block. These attributes are prefixed with `data-` and can control various aspects of the quiz functionality.

1. Randomization (`data-randomize`):

   - Shuffles options in single-choice, multiple-choice and matrix quizzes
   - Occurs once at initial slide load
   - Order persists during slide navigation
   - Example: `{"data-randomize": "true"}`

2. Maximum Trials (`data-max-trials`):

   - Sets maximum number of wrong attempts
   - Auto-solves quiz after reaching limit
   - Example: `{"data-max-trials": "3"}`

3. Solution Button (`data-solution-button`):

   - Controls visibility of solution button
   - Values: on|off, true|false, enable|disable
   - Numeric value = show after X trials
   - Example: `{"data-solution-button": "3"}`

4. Hint Button (`data-hint-button`):

   - Controls visibility of hint button
   - Similar to solution button settings
   - Numeric value = show hints after X trials
   - Example: `{"data-hint-button": "2"}`

5. Partial Solutions (`data-show-partial-solution`):

   - Shows which answers are correct in complex quizzes
   - Applies to gap-texts and matrix quizzes
   - Highlights correct/incorrect parts
   - Example: `{"data-show-partial-solution": "true"}`

6. Scoring (`data-score`):

   - Sets quiz value for SCORM exports
   - Accepts integers or floats
   - Default value is 1
   - Example: `{"data-score": "2.5"}`

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
  "title": "`Gallery`",
  "indent": 3,
  "body": [
    "A gallery is simply a collection of multimedia links",
    {
      "type": "Gallery",
      "body": [
        {
          "type": "link",
          "linkType": "image",
          "url": "https://liascript.github.io/img/LiveEditor.jpg",
          "alt": "LiaScript Live-Editor",
          "title": "More and optional information."
        },
        {
          "type": "link",
          "linkType": "audio",
          "url": "https://soundcloud.com/magnetic-magazine/magnetics-elm-podcast-one-more",
          "alt": "Magnetic's ELM Podcast: One More Summer Sun"
        },
        {
          "type": "link",
          "linkType": "video",
          "url": "https://www.youtube.com/watch?v=q_Usix3nyGA",
          "alt": "Some random video"
        },
        {
          "type": "link",
          "linkType": "embed",
          "url": "https://falstad.com/circuit/circuitjs.html"
        }
      ]
    }
  ]
}
```

### Tasks

``` markdown
### `Tasks`

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
  "title": "`Tasks`",
  "indent": 3,
  "body": [
    "Tasks are defined by a task and by a done list:",
    {
      "type": "Tasks",
      "body": ["task 1", "task 2", "task 3"],
      "done": [true, false, true]
    },
    "Additionally it is possible to define a done list with only checked positions:",
    {
      "type": "tasks",
      "body": ["task 1", "task 2", "task 3"],
      "done": [0, 2]
    }
  ]
}
```

### Tables

``` markdown
### `Table`

Tables are defined by a head and a body, the alignment is optional

| head 1 | head 2 |    __head 3__   |
| :---- | ------: | :-------------: |
| __1__ |       2 | $ \frac{9}{3} $ |
| 4     |       5 |        6        |
| 7     |       8 |        9        |
```

---

``` json
{
  "title": "`Table`",
  "indent": 3,
  "body": [
    "Tables are defined by a head and a body, the alignment is optional",
    {
      "type": "Table",
      "head": [
        "head 1",
        "head 2",
        [
          {
            "type": "bold",
            "body": "head 3"
          }
        ]
      ],
      "alignment": ["left", "right", "center"],
      "body": [
        [{ "type": "bold", "body": "1" }, "2", { "type": "formula", "body": "\\frac{9}{3}" }],
        ["4", "5", "6"],
        ["7", "8", "9"]
      ]
    }
  ]
}
```

#### Visualizations

Tables in LiaScript are not only used for data representation, but also for visualizations. You can use the `attr` parameter to define how the table should be displayed.

1. `data-type` - Sets visualization type:

   - Common charts: `bar, line, pie, scatter`
   - Advanced charts: `boxplot, funnel, graph, heatmap`
   - Special types: `map, parallel, radar, sankey`
   - Use `none` to show only table view

2. Display Controls:

   - `data-show`: Show visualization immediately
   - `data-transpose`: Switch rows and columns
   - `data-sortable`: Enable/disable column sorting

3. Chart Labels:

   - `data-title`: Custom chart title
   - `data-xlabel`: X-axis label
   - `data-ylabel`: Y-axis label
   - `data-xlim`: X-axis limits (format: "min,max")
   - `data-ylim`: Y-axis limits (format: "min,max")

4. Layout Options:

   - `data-orientation`: Switch between vertical/horizontal
   - `data-src`: External data source (e.g., GeoJSON for maps)

### Code-Snippets

The code is passed as a single string or a list of strings, language, title, and closed are optional parameters.

```` markdown
### `Code`

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
  "title": "`Code`",
  "indent": 3,
  "body": [
    {
      "type": "Code",
      "body": [
        "This is a simple code block",
        "with multiple lines",
        "and a specific language",
        "for syntax highlighting"
      ],
      "language": "javascript",
      "title": "test.js",
      "closed": true
    }
  ]
}
```


### Projects

A project can be defined by a single code-block or by a list of code-blocks.
Additionally it is possible to add an appendix, which is either a script or a macro that evaluates to a script, and that defines how the code can be made executable.


```` markdown
### `Project`

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
  "title": "`Project`",
  "indent": 3,
  "body": [
    {
      "type": "Project",
      "body": [
        {
          "type": "Code",
          "body": ["var i = 0;"],
          "language": "javascript",
          "title": "var.js"
        },
        {
          "type": "Code",
          "body": "alert(\"Hallo Welt\")",
          "language": "javascript",
          "title": "alert.js"
        }
      ],
      "execute": "@eval"
    }
  ]
}
```

### HTML

HTML on the block level is used to include raw HTML code into the LiaScript document. It works slightly different than the inline HTML. Inline HTML can only contain inline elements, while block-level HTML can contain any blocks and inline elements, which will be separated by empty lines, including paragraphs, tables, and other block-level elements.

``` markdown
### `Html`

<section "style"="color: red;">

This is a simple HTML element

| head 1 | head 2 |    __head 3__   |
| :----- | -----: | :-------------: |
| __1__  |      2 | $ \frac{9}{3} $ |
| 4      |      5 |         6       |
| 7      |      8 |         9       |

</section>
```

---

``` json
{
  "title": "`Html`",
  "indent": 3,
  "body": [
    {
      "type": "Html",
      "htmlTag": "section",
      "body": [
        {
          "type": "Paragraph",
          "body": "This is a simple HTML element"
        },
        {
          "type": "Table",
          "head": [
            "head 1",
            "head 2",
            [
              {
                "type": "bold",
                "body": "head 3"
              }
            ]
          ],
          "alignment": ["left", "right", "center"],
          "body": [
            [
              {
                "type": "bold",
                "body": "1"
              },
              "2",
              {
                "type": "formula",
                "body": "\\frac{9}{3}"
              }
            ],
            ["4", "5", "6"],
            ["7", "8", "9"]
          ]
        }
      ],
      "attr": {
        "style": "color: red;"
      }
    }
  ]
}

```

## Inline Elements

### Basic Text Formatting

``` json
{
  "sections": [
    {
      "indent": 2,
      "title": "Text Formatting",
      "body": [
        {
          "type": "Paragraph",
          "body": [
            "Basic text formatting includes: ",
            {
              "type": "bold",
              "body": "bold text"
            },
            ", ",
            {
              "type": "italic",
              "body": "italic text"
            },
            ", and ",
            {
              "type": "underline",
              "body": "underlined text"
            }
          ]
        }
      ]
    }
  ]
}
```

Renders as: Basic text formatting includes: bold text, italic text, and <del>underlined text</del>

``` markdown
## Text Formatting

Basic text formatting includes: __bold text__, _italic text_, and ~~underlined text~~
```

### Text Decorations

``` json
{
  "indent": 2,
  "title": "Text Decoration",
  "body": [
    {
      "type": "Paragraph",
      "body": [
        {
          "type": "strike",
          "body": "struck through"
        },
        " and ",
        {
          "type": "sup",
          "body": "superscript"
        },
        " and symbols like ",
        {
          "type": "symbol",
          "body": "→"
        }
      ]
    }
  ]
}
```

Renders as: <del>struck through</del> and ^superscript^ and symbols like →

``` markdown
## Text Decoration

~struck through~ and ^superscript^ and symbols like →
```

### Technical Elements

``` json
{
  "indent": 2,
  "title": "Technical Elements",
  "body": [
    {
      "type": "Paragraph",
      "body": [
        "Formula: ",
        {
          "type": "formula",
          "body": "E = mc^2"
        },
        " and code: ",
        {
          "type": "code",
          "body": "const x = 42;"
        }
      ]
    }
  ]
}
```

Renders as

``` markdown
## Technical Elements

Formula: $ E = mc^2 $ and code: `const x = 42;`
```

### Links & Multimedia

There are also links and multimedia embeddings, which can be used to embed to external resources.

``` json
{
  "title": "`link`",
  "indent": 3,
  "body": [
    {
      "type": "link",
      "url": "https://liascript.github.io/LiveEditor"
    },
    {
      "type": "link",
      "url": "https://liascript.github.io/LiveEditor",
      "title": "More and optional information."
    },
    {
      "type": "link",
      "url": "https://liascript.github.io/LiveEditor",
      "body": "LiaScript Live-Editor"
    },
    {
      "type": "link",
      "url": "https://liascript.github.io/LiveEditor",
      "body": "LiaScript Live-Editor",
      "title": "More and optional information."
    }
  ]
}
```

---

``` json
{
  "title": "`multimedia`",
  "indent": 3,
  "body": [
    {
      "type": "multimedia",
      "embedType": "image",
      "url": "https://liascript.github.io/img/LiveEditor.jpg",
      "alt": "LiaScript Live-Editor",
      "title": "More and optional information."
    },
    {
      "type": "multimedia",
      "linembedTypekType": "audio",
      "url": "https://soundcloud.com/magnetic-magazine/magnetics-elm-podcast-one-more",
      "alt": "Magnetic's ELM Podcast: One More Summer Sun"
    },
    {
      "type": "multimedia",
      "embedType": "video",
      "url": "https://www.youtube.com/watch?v=q_Usix3nyGA",
      "alt": "Some random video"
    },
    {
      "type": "multimedia",
      "embedType": "embed",
      "url": "https://falstad.com/circuit/circuitjs.html"
    }
  ]
}
```

`image` links are used to embed images, `audio` links for audio files, `video` links for videos, and `embed` links for any other types of content.

``` markdown
### `multimedia`

![LiaScript Live-Editor](https://liascript.github.io/img/LiveEditor.jpg "More and optional information.")

?[Magnetic's ELM Podcast: One More Summer Sun](https://soundcloud.com/magnetic-magazine/magnetics-elm-podcast-one-more)

!?[Some random video](https://www.youtube.com/watch?v=q_Usix3nyGA)

??[](https://falstad.com/circuit/circuitjs.html)
```

### Inline effects

``` json
{
  "title": "`effect`",
  "indent": 3,
  "body": [
    {
      "type": "Paragraph",
      "body": [
        "Effects can be inline too. This is an ordinary paragraph, with a ",
        {
          "type": "effect",
          "body": "Animated text",
          "start": 0,
          "stop": 5,
          "playback": true,
          "voice": "UK English Male"
        },
        "included"
      ]
    }
  ]
}
```

---

``` markdown
### `effect`

Effects can be inline too. This is an ordinary paragraph, with a {0-5 !> UK English Male}{Animated text}included
```

### HTML

``` json
{
  "title": "`html`",
  "indent": 3,
  "body": [
    {
      "type": "Paragraph",
      "body": [
        {
          "type": "html",
          "htmlTag": "span",
          "body": "Animated text",
          "attr": {
            "style": "background-color: red;",
            "id": "important"
          }
        }
      ]
    },
    {
      "type": "Paragraph",
      "body": [
        {
          "type": "html",
          "htmlTag": "div",
          "body": [
            {
              "type": "bold",
              "body": "LiaScript can mix with"
            }
          ],
          "attr": {
            "style": "background-color: red;",
            "id": "important"
          }
        }
      ]
    }
  ]
}
```

---

``` markdown
### `html`

<span "id"="important" "style"="background-color: red;">Animated text</span>

<div "id"="important" "style"="background-color: red;">__LiaScript can mix with__</div>
```

### `script`

``` json
{
  "title": "`script`",
  "indent": 3,
  "body": [
    {
      "type": "Paragraph",
      "body": [
        "Scripts can be included as inline elements too, like this: ",
        {
          "type": "script",
          "body": "Math.pow(2, 12);",
          "attr": {
            "run-once": true
          }
        }
      ]
    },
    "Or as an inline element directly:",
    {
      "type": "script",
      "body": "alert('hello world')"
    }
  ]
}
```

``` markdown
### `script`

Scripts can be included as inline elements too, like this: <script "run-once"="true">Math.pow(2, 12);</script>

Or as an inline element directly:

<script >alert('hello world')</script>
```

---

Script Execution Settings

1. **Value Setting** (`value`):

   - Sets default input value
   - Type depends on `@input` macro usage
   - Example: `{"value":"42"}`

2. **Update Behavior** (`update-on-change`):

   - Controls when script executes on input changes
   - Default behavior varies by input type
   - Values: `true|false`
   - Example: `{"update-on-change":"true"}`

3. **Input Visibility** (`input-active`, `input-always-active`):

   - `input-active`: Shows input on first click, hides on blur
   - `input-always-active`: Input remains visible permanently
   - Example: `{"input-always-active":"true"}`

4. **Execution Control** (`run-once`):

   - Executes script only once
   - Preserves result for future displays
   - Example: `{"run-once":"true"}`

5. **Code Editing** (`modify`):

   - Controls code editability
   - Can show/hide specific code sections
   - Values:

     - `false`: Disables editing
     - Pattern string: Shows only matching sections

   - Example: `{"modify":"// visible\\n"}` or `{"modify": false}`

     ```markdown
     <script modify="// visible\n">
     // hidden code
     // visible
     console.log("visible code")
     // visible
     // hidden code
     </script>
     ```

6. **Threading** (`worker`):

   - Runs script in worker thread
   - For heavy computations
   - Cannot modify DOM
   - Example: `{"worker":"true"}`

7. **Script Type** (`type`):

   - Sets script language/environment
   - Default: `text/javascript`
   - Options: `python`, `ruby`, etc.
   - Example: `{"type":"text/python"}`

## Metadata


### Basic Information

- author: Define course authors (separate multiple with semicolons)

- comment: Short course description for home screen (single paragraph)

- date: Last update timestamp

- email: Contact information

- edit: Link to edit source (GitHub/LiveEditor)

- logo: Background image for course card

- icon: Custom icon replacing default hummingbird

- version: Course versioning (major.minor.patch)

### Attribution & Source

- attribute: Credit third-party resources/libraries

- repository: Original source repository link

### Internationalization

- language: Set UI language (e.g., "en", "de")
- translation: Links to translated versions
- font: Custom font families for special characters
- narrator: Default text-to-speech voice for comments and effects

  Use the following table to select a voice for your course:

  | Female                        | Male                        |
  | ----------------------------- | --------------------------- |
  | UK English Female             | UK English Male             |
  | US English Female             | US English Male             |
  |                               | Afrikaans Male              |
  |                               | Albanian Male               |
  | Arabic Female                 | Arabic Male                 |
  |                               | Armenian Male               |
  | Australian Female             | Australian Male             |
  | Bangla Bangladesh Female      | Bangla Bangladesh Male      |
  | Bangla India Female           | Bangla India Male           |
  |                               | Bosnian Male                |
  | Brazilian Portuguese Female   | Brazilian Portuguese Male   |
  |                               | Catalan Male                |
  | Chinese Female                | Chinese Male                |
  | Chinese (Hong Kong) Female    | Chinese (Hong Kong) Male    |
  | Chinese Taiwan Female         | Chinese Taiwan Male         |
  |                               | Croatian Male               |
  | Czech Female                  | Czech Male                  |
  | Danish Female                 | Danish Male                 |
  | Deutsch Female                | Deutsch Male                |
  | Dutch Female                  | Dutch Male                  |
  |                               | Esperanto Male              |
  |                               | Estonian Male               |
  | Filipino Female               |                             |
  | Finnish Female                | Finnish Male                |
  | French Canadian Female        | French Canadian Male        |
  | French Female                 | French Male                 |
  | Greek Female                  | Greek Male                  |
  | Hindi Female                  | Hindi Male                  |
  | Hungarian Female              | Hungarian Male              |
  |                               | Icelandic Male              |
  | Indonesian Female             | Indonesian Male             |
  | Italian Female                | Italian Male                |
  | Japanese Female               | Japanese Male               |
  | Korean Female                 | Korean Male                 |
  | Latin Female                  | Latin Male                  |
  |                               | Latvian Male                |
  |                               | Macedonian Male             |
  | Moldavian Female              | Moldavian Male              |
  |                               | Montenegrin Male            |
  | Nepali                        | Nepali                      |
  | Norwegian Female              | Norwegian Male              |
  | Polish Female                 | Polish Male                 |
  | Portuguese Female             | Portuguese Male             |
  | Romanian Female               | Romanian Male               |
  | Russian Female                | Russian Male                |
  |                               | Serbian Male                |
  |                               | Serbo-Croatian Male         |
  | Sinhala                       | Sinhala                     |
  | Slovak Female                 | Slovak Male                 |
  | Spanish Female                | Spanish Male                |
  | Spanish Latin American Female | Spanish Latin American Male |
  |                               | Swahili Male                |
  | Swedish Female                | Swedish Male                |
  | Tamil Female                  | Tamil Male                  |
  | Thai Female                   | Thai Male                   |
  | Turkish Female                | Turkish Male                |
  | Ukrainian Female              |                             |
  | Vietnamese Female             | Vietnamese Male             |
  |                               | Welsh Male                  |


### External Resources

- link: Load external CSS files
- script: Load external JavaScript files
- import: Import macros from other LiaScript courses

### Display Settings

- mode: Default view (Presentation/Slides/Textbook)
- dark: Default theme preference (true/false)
- classroom: Enable/disable classroom features
- sharing: Enable/disable sharing options
- translateWithGoogle: Enable/disable Google Translate

### Functional Settings

- onload: JavaScript executed before course loads
- style: Custom CSS definitions
- persistent: Keep DOM elements across slides

### Helper Functions

- uid: Generate unique identifiers
- formula: Define KaTeX formula macros
- input: Access user input in scripts
- output: Define default output for code blocks