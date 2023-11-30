const express = require('express')
const app = express()
const payload = {message: 'Im all right !'}
const config = require('@hmcts/properties-volume').addTo(require('config'))
const port = config.get('server.port')

const healthcheck = require('@hmcts/nodejs-healthcheck')
healthcheck.addTo(app,
  {
    checks: {
      webCheck: healthcheck.web("http://0.0.0.0:${port}/")
    },
    buildInfo: {
      'chart-testing': 'nodejs-chart test'
    }
  })

app.get('/', (req, res) => res.send(payload))
  .listen(port, () => console.log(`chart-nodeJs test app listening on http://0.0.0.0:${port}`))
