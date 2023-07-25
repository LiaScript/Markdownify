import liascriptify from '../dist/lib.js'

import * as example from '../src/example.json'

liascriptify(example)
  .then((doc) => {
    console.log('ok', doc)
  })
  .catch((err) => {
    console.warn('err', err)
  })
