const http = require("http");

const server = http.createServer((req, res) => {
    if (req.url === "/health") {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ status: "healthy" }));
        return;
    }

    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("Node.js CI/CD Demo Application is running!");
});

server.listen(3000, "0.0.0.0", () => {
    console.log("Server running on port 3000");
});
