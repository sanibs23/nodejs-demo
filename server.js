
const express = require("express");
const helmet = require("helmet");
const app = express();

// Security best practices
app.disable('x-powered-by');
app.use(helmet());

const port = process.env.PORT || 5000;


app.get("/", (req, res) => {
  res.status(200).json({
    message: "Hello World!",
  });
});

// Basic error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Internal Server Error" });
});

app.listen(port, () => {
  console.log("Listening on " + port);
});

module.exports = app;