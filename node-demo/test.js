const assert = require("assert");
const http = require("http");
const app = require("./app");

const PORT = 3000;

app.listen(PORT, "127.0.0.1", () => {
    console.log(`Test server started on port ${PORT}`);

    const req = http.get(`http://127.0.0.1:${PORT}/health`, (res) => {
        let data = "";

        res.on("data", (chunk) => {
            data += chunk;
        });

        res.on("end", () => {
            try {
                assert.strictEqual(res.statusCode, 200);

                const response = JSON.parse(data);

                assert.strictEqual(response.status, "healthy");

                console.log("Node.js health check test passed!");

                app.close(() => {
                    process.exit(0);
                });

            } catch (error) {
                console.error("Node.js test failed:", error.message);

                app.close(() => {
                    process.exit(1);
                });
            }
        });
    });

    req.on("error", (error) => {
        console.error("Node.js test failed:", error.message);

        app.close(() => {
            process.exit(1);
        });
    });
});
