const assert = require("assert");
const http = require("http");

const app = require("./app");

const req = http.get("http://localhost:3000/health", (res) => {
    let data = "";

    res.on("data", (chunk) => {
        data += chunk;
    });

    res.on("end", () => {
        assert.strictEqual(res.statusCode, 200);

        const response = JSON.parse(data);

        assert.strictEqual(response.status, "healthy");

        console.log("Node.js health check test passed!");

        app.close();
    });
});

req.on("error", (error) => {
    console.error("Node.js test failed:", error);
    process.exit(1);
});
