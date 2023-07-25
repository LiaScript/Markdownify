// @ts-ignore
import { Elm } from './elm/Worker.elm'

import * as example from './example.json'

export function liascriptify(
  json: any,
  callback: (msg: [boolean, string]) => void
) {
  const app = Elm.Worker.init({
    flags: JSON.stringify(json),
  })

  app.ports.outPort.subscribe((msg: [boolean, string]) => {
    callback(msg)
  })
}

liascriptify(example, function (args) {
  console.warn('liascriptify loaded', args)
})
