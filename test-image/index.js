const express = require("express");
const app = express();
const PORT = process.env.NODE_PORT;
const payload = { message: "Im all right !" };

app
  .get("/", (_, res) => res.send(payload))
  .get("/health", (_, res) => res.send(payload))
  .listen(PORT, () => console.log(`App listenning on http://0.0.0.0:${PORT}`));
