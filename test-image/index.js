const express = require('express')
const app = express()
const payload = {message: 'Im all right !'}
const config = require('@hmcts/properties-volume').addTo(require('config'))
console.log("config is: " +JSON.stringify(config))
const port = config.get('server.port')

app.get('/', (req, res) => res.send(payload))
  .get('/health/liveness', (req, res) =>  res.send(payload) )
  .get('/health', (req, res) => {
    try {
      config.get('secrets.bulk-scan.idam-client-secret')
      config.get('secrets.bulk-scan.s2s-secret')
      config.get('secrets.s2s.microservicekey-ccd-admin')
      config.get('secrets.s2s.microservicekey-ccd-data')
      res.send(payload)
    } catch (error) {
      console.log(`ERROR:` + error)
      res.sendStatus(500)
    }
  })
  .listen(port, () => console.log(`chart-nodeJs test app listening on http://0.0.0.0:${port}`))
