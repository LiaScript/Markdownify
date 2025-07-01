// @ts-ignore
import { Elm } from './elm/Demo.elm'

import * as example from './example.json'

const app = Elm.Demo.init({
  node: document.getElementById('app'),
  flags: JSON.stringify(example),
})
