const express = require("express");
const app = express();
const PORT = process.env.NODE_PORT;
const fsPromise = require('fs').promises;
const payload = { message: "Im all right !" };
const expectedfiles=[
  "/mnt/secrets/bulk-scan/idam-client-secret",
  "/mnt/secrets/bulk-scan/s2s-secret",
  "/mnt/secrets/s2s/microservicekey-ccd-admin",
  "/mnt/secrets/s2s/microservicekey-ccd-data",
]


app
  .get("/", (req, res) => res.send(payload))
  .get("/health",  (req, res) => {
    files = expectedfiles.map( file => fsPromise.open(file, 'r' ))
    Promise.all(files)
    .then( files =>  res.send(payload) )  
    .catch( err => {
      console.log(`ERROR:`+err);
      res.sendStatus(500);
    });
  })
  .listen(PORT, () => console.log(`App listenning on http://0.0.0.0:${PORT}`));
