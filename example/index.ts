import liascriptify from './node_modules/@liascript/markdownify/dist/lib'

import * as example from '../src/example.json'

liascriptify(example)
  .then((doc: string) => {
    console.log('ok', doc)
  })
  .catch((err: string) => {
    console.warn('err', err)
  })
