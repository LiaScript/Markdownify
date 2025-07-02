window.LiaScriptify = function (json) {
  if (typeof json === 'string') {
    json = JSON.parse(json)
  }

  return parseMeta(json, true) + json.sections.map(parseSection).join('\n\n')
}

function parseMeta(obj, large = false) {
  // obj.meta is expected to be an object (dictionary) of meta fields
  if (!obj || typeof obj.meta !== 'object' || obj.meta === null) return ''

  // Convert meta fields to the expected format
  const metaEntries = Object.entries(obj.meta).map(([k, v]) => {
    if (Array.isArray(v)) {
      // Multi-line meta
      return `${k}\n${v.join('\n')}\n@end`
    } else {
      // Single line meta
      return `${k}: ${v}`
    }
  })

  const m = metaEntries.join('\n\n')
  if (!m.trim()) return ''

  if (large) {
    return `<!--\n\n${m}\n\n-->\n\n\n`
  } else {
    return `\n<!--\n${m}\n-->`
  }
}

function parseSection(section) {
  if (!section.title) {
    throw Error('title required')
  }

  const title = parseInlines(section.title)
  const indent = '#'.repeat(section.indent)
  const meta = parseMeta(section)
  const body = parseBlocks(section.body)

  return indent + ' ' + title + meta + '\n\n' + body
}

function parseBlocks(blocks) {
  return blocks.map(parseBlock).join('\n\n')
}

function parseBlock(block) {
  if (typeof block === 'string') {
    return block
  }

  let attr = parseAttr(block)

  if (attr) {
    attr = attr + '\n'
  }

  switch (block.type) {
    case 'Paragraph':
      return attr + parseInlines(block.body)

    case 'Line':
      return attr + '---'

    case 'Comment':
      return attr + '--{{' + effect(block) + '}}--\n' + parseInlines(block.body)

    case 'Effect':
      let def = '{{' + effect(block) + '}}\n'
      let body = parseBlock(block.body)

      if (!body) {
        body =
          '***************\n\n' +
          parseBlocks(block.body) +
          '\n\n***************'
      }

      return attr + def + body

    case 'Gallery': {
      return attr + block.body.map(toReference).join('\n')
    }

    case 'Formula': {
      return attr + '$$\n' + stringOrList(block.body) + '\n$$'
    }

    case 'Quote': {
      let by = parseInlines(block.by)
      let body = parseBlock(block.body) || parseBlocks(block.body)

      if (by) {
        body = body + '\n\n-- ' + by
      }

      return (
        attr +
        body
          .split('\n')
          .map((line) => '> ' + line)
          .join('\n')
      )
    }

    case 'List': {
      let body = block.body.map((b) => parseBlock(b) || parseBlocks(b))

      if (block.ordered) {
        body = body.map((b, i) =>
          b
            .split('\n')
            .map((line, j) => (j ? '   ' + line : ++i + '. ' + line))
            .join('\n')
        )
      } else {
        body = body.map((b) =>
          b
            .split('\n')
            .map((line, j) => (j ? '  ' : '* ') + line)
            .join('\n')
        )
      }

      body = body.join('\n\n')

      return attr + body
    }

    case 'Html': {
      attr = parseAttr(block, false)

      let tag = block.htmlTag

      return (
        '<' +
        tag +
        ' ' +
        attr +
        '>\n' +
        (parseBlock(block.body) || parseBlocks(block.body)) +
        '\n</' +
        tag +
        '>'
      )
    }
    case 'Code': {
      let body = stringOrList(block.body)
      let title = block.title || ''
      let closed = block.closed || false
      let language = block.language || ''

      if (language && !title) {
        body = '```` ' + language + '\n' + body + '\n````'
      } else if (language && title) {
        body =
          '```` ' +
          language +
          (closed ? '  -' : '  ') +
          title +
          '\n' +
          body +
          '\n````'
      } else {
        body = '````\n' + body + '\n````'
      }

      return attr + body + execute(block)
    }
    case 'Table': {
      let head = block.head.map(parseInlines)

      let alignment = block.alignment
      if (alignment) {
        alignment = alignment.map((o) => {
          switch (o) {
            case 'left':
              return ':----'
            case 'right':
              return '----:'
            case 'center':
              return ':---:'
            default:
              return '-----'
          }
        })
      } else {
        alignment = Array(head.length).fill('-----')
      }

      let body = block.body.map((row) => row.map(parseInlines).join(' | '))

      return (
        attr +
        [head.join(' | '), alignment.join(' | '), ...body]
          .map((l) => '| ' + l + ' |')
          .join('\n')
      )
    }

    case 'Tasks': {
      const done = marked(block.done)

      return (
        attr +
        block.body
          .map((task, i) => (done.includes(i) ? '- [X] ' : '- [ ] ') + task)
          .join('\n') +
        execute(block)
      )
    }

    case 'Ascii': {
      const title = block.title ? '  ' + parseInlines(block.title) : ''
      return (
        attr + '```` ascii' + title + '\n' + stringOrList(block.body) + '\n````'
      )
    }

    case 'Chart': {
      return (
        attr +
        stringOrList(block.body)
          .split('\n')
          .map((line) => '    ' + line)
          .join('\n')
      )
    }

    case 'Quiz': {
      let quiz = ''
      let hints = block.hints
        ? '\n' +
          block.hints.map((hint) => '[[?]]' + parseInlines(hint)).join('\n')
        : ''

      let answer = block.answer
        ? '\n*************\n\n' +
          (parseBlock(block.answer) || parseBlocks(block.answer)) +
          '\n\n*************\n'
        : ''

      switch (block.quizType) {
        case 'input': {
          quiz = inputText(block)
          break
        }
        case 'selection': {
          quiz = inputSelection(block)
          break
        }
        case 'single-choice': {
          let solution = marked(block.solution)
          quiz = block.body
            .map(
              (option, i) =>
                (solution.includes(i) ? '[(X)] ' : '[( )] ') + option
            )
            .join('\n')
          break
        }

        case 'multiple-choice': {
          let solution = marked(block.solution)
          quiz = block.body
            .map(
              (option, i) =>
                (solution.includes(i) ? '[[X]] ' : '[[ ]] ') + option
            )
            .join('\n')
          break
        }

        case 'matrix': {
          let head = block.head
            .map(parseInlines)
            .map((cell) =>
              cell.includes(')') ? '[' + cell + ']' : '(' + cell + ')'
            )

          let body = block.body.map((row) => {
            const solution = marked(row.solution)
            let rowStr = '[ '

            if (row['single-choice']) {
              rowStr += head
                .map((_, i) => (solution.includes(i) ? '(X)' : '( )'))
                .join('  ')
            }

            if (row['multiple-choice']) {
              rowStr += head
                .map((_, i) => (solution.includes(i) ? '[X]' : '[ ]'))
                .join('  ')
            }

            return rowStr + '] ' + parseInlines(row.body)
          })

          quiz = '[ ' + head.join('  ') + ' ]\n' + body.join('\n')

          break
        }

        case 'gap-text': {
          quiz = parseBlock(block.body)
          break
        }

        case 'generic':
          quiz = '[[!]]'
          break
      }

      return attr + quiz + hints + answer + execute(block)
    }

    default:
      return parseInlines(block)
  }
}

function parseInlines(e) {
  if (e === undefined) return ''

  if (typeof e === 'string') {
    return e
  }

  if (Array.isArray(e)) {
    return e.map(parseInlines).join('')
  }

  switch (e.type) {
    case 'bold':
      return '__' + parseInlines(e.body) + '__' + parseAttr(e)
    case 'italic':
      return '_' + parseInlines(e.body) + '_' + parseAttr(e)
    case 'strike':
      return '~~' + parseInlines(e.body) + '~~' + parseAttr(e)
    case 'underline':
      return '~' + parseInlines(e.body) + '~' + parseAttr(e)
    case 'sup':
      return '^' + parseInlines(e.body) + '^' + parseAttr(e)
    case 'formula':
      return '$' + e.body + '$' + parseAttr(e)
    case 'symbol':
      return e.body + parseAttr(e)
    case 'code':
      return '`' + e.body + '`' + parseAttr(e)
    case 'multimedia': {
      return toReference(e)
    }
    case 'link': {
      if (!e.body && !e.title && e.url) {
        return e.url + parseAttr(e)
      }
      if (e.body) {
        e.alt = e.body
      }

      return toReference(e)
    }
    case 'script': {
      return `<script ${parseAttr(e, false)}>${stringOrList(e.body)}</script>`
    }

    case 'html': {
      const tag = e.htmlTag

      return `<${tag} ${parseAttr(e, false)}>${parseInlines(e.body)}</${tag}>`
    }

    case 'footnote': {
      return '[^' + e.body + ']' + parseAttr(e)
    }

    case 'select': {
      return inputSelection(e) + parseAttr(e)
    }

    case 'input': {
      return inputText(e) + parseAttr(e)
    }

    case 'effect': {
      return '{' + effect(e) + '}{' + parseInlines(e.body) + '}' + parseAttr(e)
    }
  }
}

function toReference(e) {
  let ref = ''
  const url = e.url
  const title = parseInlines(e.title)
  const alt = parseInlines(e.alt)

  if (alt && title && url) {
    ref = '[' + alt + '](' + url + ' "' + title + '")'
  } else if (alt && url) {
    ref = '[' + alt + '](' + url + ')'
  } else if (url && title) {
    ref = '[](' + url + ' "' + title + '")'
  } else if (url) {
    ref = url
  }

  switch (e.embedType) {
    case 'image':
      ref = '!' + ref
      break
    case 'audio':
      ref = '?' + ref
      break
    case 'video':
      ref = '!?' + ref
      break
    case 'embed':
      ref = '??' + ref
      break
  }

  return ref + parseAttr(e)
}

function parseAttr(e, asComment = true) {
  if (typeof e !== 'object' || !e.attr) {
    return ''
  }

  let attr = e.attr
  if (typeof attr === 'object') {
    attr = Object.entries(attr)
      .map(([k, v]) => {
        if (typeof v === 'boolean') {
          v = v ? 'true' : 'false'
        } else if (typeof v === 'number') {
          // Keep as is (int or float)
        } else if (typeof v === 'object') {
          v = JSON.stringify(v)
        }
        return `${k}="${v}"`
      })
      .join(' ')
  }

  if (typeof attr !== 'string') {
    return ''
  }
  if (asComment) {
    return '<!-- ' + attr + ' -->'
  }

  return attr
}

function execute(obj) {
  if (!obj.execute) {
    return ''
  }

  return '\n' + stringOrList(obj.execute)
}

function stringOrList(e) {
  if (Array.isArray(e)) return e.join('\n')

  return e
}

function inputText(obj) {
  const solution = typeof obj.solution === 'string' ? obj.solution : ''
  const length = typeof obj.length === 'number' ? obj.length : solution.length

  if (length < solution.length) {
    throw new Error(
      'length must be greater than or equal to the length of the solution'
    )
  }

  return '[[' + solution + ' '.repeat(length - solution.length) + ']]'
}

function inputSelection(obj) {
  const options = Array.isArray(obj.body) ? obj.body : []
  const solution = marked(obj.solution)

  return (
    '[[' +
    options.map((o, i) => (solution.includes(i) ? `( ${o} )` : o)).join(' | ') +
    ']]'
  )
}

function effect(obj) {
  const begin = start_(obj)
  const end = stop_(obj)
  const playback = playback_(obj)
  const voice = voice_(obj)

  let steps = ''

  if (begin && end) {
    steps = begin + '-' + end
  } else if (begin) {
    steps = begin
  }

  let play = ''

  if (playback && voice) {
    play = '!> ' + voice
  } else if (playback) {
    play = '!>'
  } else if (voice) {
    play = voice
  }

  if (steps && play) {
    return steps + ' ' + play
  }

  return steps + play
}

function marked(value) {
  // Single integer
  if (typeof value === 'number' && Number.isInteger(value)) {
    return [value]
  }

  // List of integers
  if (
    Array.isArray(value) &&
    value.every((v) => typeof v === 'number' && Number.isInteger(v))
  ) {
    return value
  }

  // List of booleans
  if (Array.isArray(value) && value.every((v) => typeof v === 'boolean')) {
    // Return indices where value is true
    return value.map((b, i) => (b ? i : null)).filter((i) => i !== null)
  }

  // Not matched
  return []
}

function voice_(obj) {
  // Returns the value of obj.voice as a string, or null if not present
  return typeof obj.voice === 'string' ? obj.voice : null
}

function playback_(obj) {
  // Returns the value of obj.playback as a boolean, or false if not present
  return typeof obj.playback === 'boolean' ? obj.playback : false
}

function start_(obj) {
  // Returns obj.start as a string (if present and integer), or null
  if (typeof obj.start === 'number' && Number.isInteger(obj.start)) {
    return String(obj.start)
  }
  return null
}

function stop_(obj) {
  // Returns obj.stop as a string (if present and integer), or null
  if (typeof obj.stop === 'number' && Number.isInteger(obj.stop)) {
    return String(obj.stop)
  }
  return
}

window.LiaScriptify = LiaScriptify
