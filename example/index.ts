import liascriptify from './node_modules/@liascript/markdownify/dist/lib'

const example = {
  meta: {
    author: 'Superhero',
    email: 'superhero@web.de',
  },
  sections: [
    {
      title: 'Main Title',
      indent: 1,
      body: [
        'This can be either a list of Strings',
        'that are interpreted as Markdown-blocks',
        {
          paragraph: [
            {
              string: 'Or a set of ',
            },
            {
              bold: [
                {
                  string: 'more sophisticated ',
                },
                {
                  superscript: 'elements',
                },
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
