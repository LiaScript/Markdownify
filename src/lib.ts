// @ts-ignore
import { Elm } from './elm/Worker.elm'

export default function liascriptify(json: any): Promise<string> {
  return new Promise((resolve, reject) => {
    const app = Elm.Worker.init({
      flags: typeof json === 'string' ? json : JSON.stringify(json),
    })

    app.ports.outPort.subscribe(([ok, rslt]: [boolean, string]) => {
      if (ok) {
        resolve(rslt)
      } else {
        reject(rslt)
      }
    })
  })
}
