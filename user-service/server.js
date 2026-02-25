const express = require("express");
const app = express();
const PORT = 3001;

app.get("/health", (req, res) => {
  res.json({ status: "User Service is healthy" });
});

app.get("/users", (req, res) => {
  res.json([
    { id: 1, name: "John Doe" },
    { id: 2, name: "Jane Smith" }
  ]);
});

app.listen(PORT, () => {
  console.log(`User Service running on port ${PORT}`);
});